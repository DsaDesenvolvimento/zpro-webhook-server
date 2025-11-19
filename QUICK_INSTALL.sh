#!/bin/bash
#
# INSTALAÇÃO RÁPIDA - Z-PRO WEBHOOK SERVER
# Copie e cole este script inteiro no servidor 217.196.63.63
#
# USO:
#   ssh user@217.196.63.63
#   # Cole todo este script e pressione Enter
#

set -e

echo "🚀 Instalando Z-PRO Webhook Server..."
echo ""

# Tornar-se root
sudo bash << 'ROOTSCRIPT'

# Atualizar e instalar dependências
echo "[1/10] Atualizando sistema..."
apt-get update -qq
apt-get install -y python3 python3-pip python3-venv nginx supervisor git curl jq

# Criar usuário
echo "[2/10] Criando usuário zpro..."
if ! id "zpro" &>/dev/null; then
    useradd -m -s /bin/bash zpro
fi

# Criar diretório
echo "[3/10] Criando diretório..."
mkdir -p /home/zpro/webhook
cd /home/zpro/webhook

# Criar ambiente virtual
echo "[4/10] Criando ambiente virtual..."
python3 -m venv venv
source venv/bin/activate

# Instalar pacotes
echo "[5/10] Instalando pacotes Python..."
pip install --quiet --upgrade pip
pip install --quiet flask==3.0.0 gunicorn==21.2.0 requests==2.31.0

# Criar app.py
echo "[6/10] Criando aplicação Flask..."
cat > app.py << 'ENDAPP'
#!/usr/bin/env python3
"""Z-PRO Webhook Server"""
from flask import Flask, request, jsonify
from datetime import datetime
import json, os, logging
from logging.handlers import RotatingFileHandler

app = Flask(__name__)

# Logging
if not os.path.exists('logs'):
    os.makedirs('logs')
handler = RotatingFileHandler('logs/zpro_webhook.log', maxBytes=10240000, backupCount=10)
handler.setFormatter(logging.Formatter('%(asctime)s %(levelname)s: %(message)s'))
handler.setLevel(logging.INFO)
app.logger.addHandler(handler)
app.logger.setLevel(logging.INFO)

# Dados
DATA_DIR = 'data'
if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)
CONVERSATIONS_FILE = os.path.join(DATA_DIR, 'active_conversations.json')
MESSAGES_FILE = os.path.join(DATA_DIR, 'all_messages.json')

def load_conversations():
    if os.path.exists(CONVERSATIONS_FILE):
        try:
            with open(CONVERSATIONS_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        except: return {}
    return {}

def save_conversations(conversations):
    with open(CONVERSATIONS_FILE, 'w', encoding='utf-8') as f:
        json.dump(conversations, f, ensure_ascii=False, indent=2, default=str)

def load_all_messages():
    if os.path.exists(MESSAGES_FILE):
        try:
            with open(MESSAGES_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        except: return []
    return []

def save_message(message_data):
    messages = load_all_messages()
    messages.append(message_data)
    if len(messages) > 10000:
        messages = messages[-10000:]
    with open(MESSAGES_FILE, 'w', encoding='utf-8') as f:
        json.dump(messages, f, ensure_ascii=False, indent=2, default=str)

@app.route('/')
def index():
    conversations = load_conversations()
    messages = load_all_messages()
    now = datetime.now()
    active_24h = 0
    for number, conv in conversations.items():
        last_msg = conv.get('last_message')
        if isinstance(last_msg, str):
            try:
                last_msg_dt = datetime.fromisoformat(last_msg)
                hours_diff = (now - last_msg_dt).total_seconds() / 3600
                if hours_diff <= 24: active_24h += 1
            except: pass

    return f"""<!DOCTYPE html><html><head><title>Z-PRO Webhook</title><meta charset="utf-8"><style>
body{{font-family:sans-serif;max-width:1200px;margin:0 auto;padding:20px;background:#f5f5f5}}
.container{{background:white;padding:30px;border-radius:10px;box-shadow:0 2px 10px rgba(0,0,0,0.1)}}
h1{{color:#25D366;border-bottom:3px solid #25D366;padding-bottom:10px}}
.stats{{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:20px;margin:30px 0}}
.stat-card{{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:white;padding:20px;border-radius:8px;text-align:center}}
.stat-card.green{{background:linear-gradient(135deg,#25D366 0%,#128C7E 100%)}}
.stat-number{{font-size:48px;font-weight:bold;margin:10px 0}}
.stat-label{{font-size:14px;opacity:0.9}}
.status{{display:inline-block;padding:5px 15px;background:#25D366;color:white;border-radius:20px;font-size:14px;font-weight:bold}}
</style></head><body><div class="container"><h1>🚀 Z-PRO Webhook Server</h1>
<p><span class="status">✅ Online</span></p>
<div class="stats">
<div class="stat-card green"><div class="stat-label">Ativas (24h)</div><div class="stat-number">{active_24h}</div></div>
<div class="stat-card"><div class="stat-label">Total Conversas</div><div class="stat-number">{len(conversations)}</div></div>
<div class="stat-card"><div class="stat-label">Mensagens</div><div class="stat-number">{len(messages)}</div></div>
</div><h2>📡 Endpoints</h2>
<ul><li><code>POST /zpro/webhook/messages</code> - Receber mensagens</li>
<li><code>GET /zpro/active</code> - Conversas ativas</li>
<li><code>GET /zpro/stats</code> - Estatísticas</li></ul>
<p style="margin-top:30px;color:#999;font-size:12px">v1.0 | {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
</div></body></html>"""

@app.route('/zpro/webhook/messages', methods=['POST'])
def webhook_messages():
    try:
        data = request.json
        app.logger.info(f'Message: {json.dumps(data)}')
        number = data.get('from') or data.get('number') or 'unknown'
        message_body = data.get('body') or data.get('message') or ''
        timestamp = datetime.now()
        conversations = load_conversations()
        if number not in conversations:
            conversations[number] = {
                'first_message': timestamp.isoformat(),
                'last_message': timestamp.isoformat(),
                'message_count': 0,
                'messages': [],
                'contact_name': data.get('pushName', 'Desconhecido')
            }
        conversations[number]['last_message'] = timestamp.isoformat()
        conversations[number]['message_count'] += 1
        conversations[number]['messages'].append({
            'body': message_body,
            'timestamp': timestamp.isoformat(),
            'direction': data.get('direction', 'incoming')
        })
        if len(conversations[number]['messages']) > 50:
            conversations[number]['messages'] = conversations[number]['messages'][-50:]
        save_conversations(conversations)
        save_message({'number': number, 'message': message_body, 'timestamp': timestamp.isoformat(), 'raw_data': data})
        return jsonify({'status': 'ok', 'timestamp': timestamp.isoformat()})
    except Exception as e:
        app.logger.error(f'Error: {str(e)}')
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/zpro/webhook/status', methods=['POST'])
def webhook_status():
    try:
        data = request.json
        app.logger.info(f'Status: {json.dumps(data)}')
        return jsonify({'status': 'ok'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/zpro/active', methods=['GET'])
def get_active_24h():
    conversations = load_conversations()
    now = datetime.now()
    active = {}
    for number, conv in conversations.items():
        last_msg = conv.get('last_message')
        if isinstance(last_msg, str):
            try:
                last_msg_dt = datetime.fromisoformat(last_msg)
                if (now - last_msg_dt).total_seconds() / 3600 <= 24:
                    active[number] = conv
            except: pass
    return jsonify({'count': len(active), 'conversations': active, 'timestamp': now.isoformat()})

@app.route('/zpro/stats', methods=['GET'])
def get_stats():
    conversations = load_conversations()
    messages = load_all_messages()
    now = datetime.now()
    active_24h = sum(1 for conv in conversations.values()
                     if isinstance(conv.get('last_message'), str) and
                     (now - datetime.fromisoformat(conv['last_message'])).total_seconds() / 3600 <= 24)
    return jsonify({
        'total_conversations': len(conversations),
        'active_24h': active_24h,
        'total_messages': sum(c.get('message_count', 0) for c in conversations.values()),
        'stored_messages': len(messages),
        'timestamp': now.isoformat()
    })

@app.route('/health')
def health_check():
    return jsonify({'status': 'healthy', 'service': 'zpro-webhook', 'timestamp': datetime.now().isoformat()})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
ENDAPP

chmod +x app.py

# Configurar Supervisor
echo "[7/10] Configurando Supervisor..."
cat > /etc/supervisor/conf.d/zpro-webhook.conf << 'ENDSUPERVISOR'
[program:zpro-webhook]
command=/home/zpro/webhook/venv/bin/gunicorn --bind 127.0.0.1:5000 --workers 4 --timeout 120 app:app
directory=/home/zpro/webhook
user=zpro
autostart=true
autorestart=true
stderr_logfile=/var/log/zpro-webhook.err.log
stdout_logfile=/var/log/zpro-webhook.out.log
ENDSUPERVISOR

# Configurar Nginx
echo "[8/10] Configurando Nginx..."
cat > /etc/nginx/sites-available/zpro-webhook << 'ENDNGINX'
server {
    listen 80;
    server_name 217.196.63.63;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
ENDNGINX

ln -sf /etc/nginx/sites-available/zpro-webhook /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Ajustar permissões
echo "[9/10] Ajustando permissões..."
chown -R zpro:zpro /home/zpro/webhook

# Iniciar serviços
echo "[10/10] Iniciando serviços..."
supervisorctl reread
supervisorctl update
supervisorctl start zpro-webhook
nginx -t && systemctl reload nginx

echo ""
echo "✅ INSTALAÇÃO CONCLUÍDA!"
echo ""
echo "Servidor rodando em: http://217.196.63.63"
echo ""
echo "Testar:"
echo "  curl http://217.196.63.63/health"
echo ""

ROOTSCRIPT

# Teste final
echo "🧪 Testando instalação..."
sleep 2
curl -s http://217.196.63.63/health | jq .

echo ""
echo "✅ TUDO PRONTO!"
echo ""
echo "Configure webhooks no Z-PRO:"
echo "  Messages: http://217.196.63.63/zpro/webhook/messages"
echo "  Status: http://217.196.63.63/zpro/webhook/status"
echo ""
