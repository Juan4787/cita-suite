#!/usr/bin/env python3
"""Conexión local a Zoho CPaaS. Secretos fuera del repositorio y de stdout."""
import argparse
import getpass
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path.home() / '.local/share/cita-suite/zoho'
CONFIG = Path.home() / '.config/cita-suite/private/zoho-cpaas.json'
REGIONS = ('com', 'eu', 'in', 'com.au', 'jp', 'com.cn')
SCOPES = ','.join(('Zeptomail.MailAgents.ALL', 'Zeptomail.Domains.ALL',
                   'Zeptomail.MailTemplates.ALL', 'Zeptomail.Suppressions.ALL',
                   'Zeptomail.email.READ'))


class ConnectionError(Exception):
    pass


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def private_write(path, value):
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    path.parent.chmod(0o700)
    fd, name = tempfile.mkstemp(prefix='.zoho-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as out:
            json.dump(value, out, ensure_ascii=False, indent=2)
            out.write('\n')
            out.flush()
            os.fsync(out.fileno())
        os.replace(name, path)
        directory = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def load_config():
    if not CONFIG.exists():
        raise ConnectionError('Falta conectar Zoho. Ejecutá el comando connect.')
    metadata = CONFIG.lstat()
    if (not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != os.getuid()
            or metadata.st_mode & 0o077):
        raise ConnectionError('El archivo de acceso debe ser privado y pertenecer a tu usuario.')
    value = json.loads(CONFIG.read_text())
    if value.get('dc') not in REGIONS:
        raise ConnectionError('La región de Zoho guardada no es válida.')
    return value


def request_json(url, headers=None, form=None):
    body = None if form is None else urllib.parse.urlencode(form).encode()
    headers = dict(headers or {})
    headers['Accept'] = 'application/json'
    if body is not None:
        headers['Content-Type'] = 'application/x-www-form-urlencoded'
    req = urllib.request.Request(url, data=body, headers=headers)
    try:
        with urllib.request.build_opener(NoRedirect()).open(req, timeout=25) as response:
            result = json.loads(response.read(2_000_000))
    except urllib.error.HTTPError as exc:
        messages = {401: 'Zoho rechazó la autorización. Revisá la conexión y su región.',
                    403: 'Zoho no concedió permiso para esta consulta.',
                    429: 'Zoho pidió esperar antes de hacer otra consulta.'}
        raise ConnectionError(messages.get(exc.code, 'Zoho no pudo completar la consulta.')) from None
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
        raise ConnectionError('No se recibió una respuesta válida de Zoho. No se reintentó automáticamente.') from None
    if not isinstance(result, dict):
        raise ConnectionError('Zoho devolvió una respuesta inesperada.')
    if result.get('error') or str(result.get('status', '')).lower() in ('failure', 'error'):
        error = result.get('error')
        messages = {'invalid_code': 'El código venció o ya se usó. Generá otro en Generate Code.',
                    'invalid_client': 'Revisá el Client ID, el Client Secret y la región.',
                    'invalid_client_secret': 'Revisá el Client Secret.',
                    'invalid_scope': 'Zoho no reconoció uno de los permisos solicitados.'}
        raise ConnectionError(messages.get(error if isinstance(error, str) else '',
                                           'Zoho rechazó la operación. Revisá los permisos y la región.'))
    return result


def save_tokens(config, result):
    access = result.get('access_token')
    refresh = result.get('refresh_token', config.get('refresh_token'))
    if not isinstance(access, str) or not access or not isinstance(refresh, str) or not refresh:
        raise ConnectionError('Zoho no entregó los accesos necesarios para mantener la conexión.')
    expiry = result.get('expires_in', 3600)
    if not isinstance(expiry, (int, float)) or not 60 <= expiry <= 86400:
        raise ConnectionError('Zoho devolvió un vencimiento inesperado.')
    config = dict(config, access_token=access, refresh_token=refresh,
                  expires_at=time.time() + expiry - 60)
    private_write(CONFIG, config)
    return config


def connect(dc, terminal=False):
    if terminal:
        fields = [getpass.getpass(label + ': ') for label in
                  ('Client ID', 'Client Secret', 'Código de Generate Code')]
    else:
        result = subprocess.run([
            'zenity', '--forms', '--title=Conectar Zoho CPaaS',
            '--text=Pegá las credenciales de Self Client aquí. No se mostrarán en el chat.\n'
                   'El código se genera al final y se usa una sola vez.',
            '--add-password=Client ID', '--add-password=Client Secret',
            '--add-password=Código de Generate Code', '--separator=\t',
            '--ok-label=Conectar', '--cancel-label=Cancelar'],
            capture_output=True, text=True, check=False)
        if result.returncode:
            raise ConnectionError('La conexión quedó pendiente; la ventana se cerró sin conectar.')
        fields = result.stdout.rstrip('\n').split('\t')
    if len(fields) != 3 or not all(field.strip() for field in fields):
        raise ConnectionError('Completá los tres campos para conectar Zoho.')
    client_id, secret, code = (value.strip() for value in fields)
    config = {'dc': dc, 'client_id': client_id, 'client_secret': secret,
              'requested_scopes': SCOPES}
    result = request_json(f'https://accounts.zoho.{dc}/oauth/v2/token', form={
        'client_id': client_id, 'client_secret': secret,
        'code': code, 'grant_type': 'authorization_code'})
    save_tokens(config, result)
    print('Credenciales guardadas en custodia privada. Falta comprobar la consulta de agentes.')


def api_get(path):
    # Fixed resources and one bounded agent-key route, never an arbitrary URL.
    is_keys = re.fullmatch(r'mailagents/[A-Za-z0-9_-]{1,128}/apikeys', path) is not None
    if path not in ('mailagents', 'domains', 'email?limit=10&offset=0') and not is_keys:
        raise ConnectionError('La consulta solicitada no está habilitada en esta herramienta.')
    config = load_config()
    if time.time() >= config.get('expires_at', 0):
        result = request_json(f"https://accounts.zoho.{config['dc']}/oauth/v2/token", form={
            'client_id': config['client_id'], 'client_secret': config['client_secret'],
            'refresh_token': config['refresh_token'], 'grant_type': 'refresh_token'})
        config = save_tokens(config, result)
    result = request_json(f"https://cpaas.zoho.{config['dc']}/v1.1/{path}", headers={
        'Authorization': 'Zoho-oauthtoken ' + config['access_token']})
    data = result.get('data')
    if path.startswith('email?') and isinstance(data, dict):
        data = data.get('logs')
    if not isinstance(data, list):
        raise ConnectionError('Zoho respondió, pero falta la lista esperada. La consulta no está verificada.')
    resource = 'apikeys' if is_keys else path.split('?')[0]
    private_write(ROOT / f"{resource}-latest.json", {
        'observed_at': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()), 'resource': path, 'response': result})
    return data


def agent_keys():
    agents = api_get('mailagents')
    active = [agent for agent in agents if isinstance(agent, dict) and agent.get('status') == 'active']
    if len(active) != 1:
        raise ConnectionError('No hay un único agente activo. La consulta de claves requiere seleccionar su agente de forma explícita.')
    key = active[0].get('mailagent_key')
    if not isinstance(key, str) or re.fullmatch(r'[A-Za-z0-9_-]{1,128}', key) is None:
        raise ConnectionError('Zoho no devolvió una identidad de agente válida para consultar sus claves.')
    return api_get(f'mailagents/{key}/apikeys')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('connect', 'status', 'agents', 'domains', 'logs', 'keys', 'scopes'))
    parser.add_argument('--dc', choices=REGIONS, default='com')
    parser.add_argument('--terminal', action='store_true', help='Captura oculta en una terminal interactiva')
    args = parser.parse_args()
    if args.command == 'scopes':
        print(SCOPES)
    elif args.command == 'connect':
        connect(args.dc, args.terminal)
    elif args.command == 'status':
        config = load_config()
        print('Credenciales locales presentes. Región:', config['dc'])
        print('La conexión remota sólo se verifica ejecutando agents, domains, logs o keys.')
    else:
        if args.command == 'keys':
            data = agent_keys()
        else:
            path = {'agents': 'mailagents', 'domains': 'domains', 'logs': 'email?limit=10&offset=0'}[args.command]
            data = api_get(path)
        print(f'Consulta autenticada correcta. Registros recibidos: {len(data)}.')
        print('Respuesta completa en custodia privada; no se imprimieron direcciones ni credenciales.')


if __name__ == '__main__':
    try:
        main()
    except (ConnectionError, OSError, ValueError, KeyError):
        # Los errores conocidos se explican sin revelar respuestas que pudieran contener secretos.
        import sys
        exc = sys.exc_info()[1]
        print(str(exc) if isinstance(exc, ConnectionError) else
              'No se pudo completar la conexión local. Revisá los archivos y permisos.', file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print('Conexión interrumpida; no se realizaron envíos.')
