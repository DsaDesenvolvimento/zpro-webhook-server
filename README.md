# Z-PRO Webhook Server

Servidor Flask para receber e rastrear webhooks do Z-PRO API (Automatix WhatsApp).

## 🚀 Instalação Rápida (1 Comando)

### No servidor 217.196.63.63:

```bash
ssh user@217.196.63.63
# Senha: fortuna731
```

Depois execute:

```bash
curl -sSL https://raw.githubusercontent.com/DsaDesenvolvimento/zpro-webhook-server/main/QUICK_INSTALL.sh | sudo bash
```

**Ou clone o repositório:**

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/DsaDesenvolvimento/zpro-webhook-server.git
cd zpro-webhook-server
sudo chmod +x install.sh
sudo ./install.sh
```

---

## 📋 O Que a Instalação Faz

1. ✅ Instala Python 3, Flask, Nginx, Supervisor
2. ✅ Cria usuário `zpro`
3. ✅ Configura ambiente virtual Python
4. ✅ Instala aplicação Flask
5. ✅ Configura Gunicorn (4 workers)
6. ✅ Configura Nginx reverse proxy
7. ✅ Inicia serviços automaticamente
8. ✅ Testa instalação

---

## 🌐 Endpoints Disponíveis

Após instalação, acesse:

- **Dashboard:** http://217.196.63.63:8081/
- **Health Check:** http://217.196.63.63:8081/health
- **Conversas Ativas:** http://217.196.63.63:8081/zpro/active
- **Estatísticas:** http://217.196.63.63:8081/zpro/stats

### Webhooks (configure no Z-PRO):

- **Messages:** http://217.196.63.63:8081/zpro/webhook/messages
- **Status:** http://217.196.63.63:8081/zpro/webhook/status

---

## 🔧 Configurar Z-PRO

1. Acesse painel Automatix: https://zproapi.automatix.global
2. Vá em **API > Webhooks**
3. Configure:
   - **Message Webhook:** `http://217.196.63.63:8081/zpro/webhook/messages`
   - **Status Webhook:** `http://217.196.63.63:8081/zpro/webhook/status`

---

## 🧪 Testar Instalação

```bash
# Health check
curl http://217.196.63.63:8081/health

# Ver estatísticas
curl http://217.196.63.63:8081/zpro/stats | jq .

# Simular mensagem
curl -X POST http://217.196.63.63:8081/zpro/webhook/messages \
  -H "Content-Type: application/json" \
  -d '{
    "from": "5511999999999",
    "body": "Teste de mensagem",
    "pushName": "João Silva"
  }'

# Ver conversas ativas
curl http://217.196.63.63:8081/zpro/active | jq .
```

---

## 📊 Gerenciar Serviço

```bash
# Ver status
sudo supervisorctl status zpro-webhook

# Reiniciar
sudo supervisorctl restart zpro-webhook

# Ver logs
sudo tail -f /var/log/zpro-webhook.out.log
```

---

## 📁 Estrutura de Arquivos

```
/home/zpro/webhook/
├── venv/                    # Ambiente virtual Python
├── app.py                   # Aplicação Flask
├── data/
│   ├── active_conversations.json
│   ├── all_messages.json
│   └── connection_status.json
└── logs/
    ├── zpro_webhook.log
    ├── access.log
    └── error.log
```

---

## 🔍 Logs

```bash
# Logs da aplicação
sudo tail -f /home/zpro/webhook/logs/zpro_webhook.log

# Logs do Supervisor
sudo tail -f /var/log/zpro-webhook.out.log
sudo tail -f /var/log/zpro-webhook.err.log

# Logs do Nginx
sudo tail -f /var/log/nginx/zpro-webhook-access.log
sudo tail -f /var/log/nginx/zpro-webhook-error.log
```

---

## 🐛 Troubleshooting

### Serviço não inicia

```bash
# Verificar logs
sudo supervisorctl tail zpro-webhook stderr

# Testar manualmente
cd /home/zpro/webhook
source venv/bin/activate
python app.py
```

### Nginx retorna 502

```bash
# Verificar se aplicação está rodando
sudo supervisorctl status zpro-webhook

# Reiniciar
sudo supervisorctl restart zpro-webhook
```

### Porta 80 em uso

```bash
# Ver o que está usando
sudo netstat -tlnp | grep :80

# Parar nginx se necessário
sudo systemctl stop nginx
```

---

## 🔒 Segurança (Opcional)

### Firewall

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### SSL/HTTPS (requer domínio)

```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d seu-dominio.com
```

---

## 📈 Monitoramento

### Script de Monitoramento

```bash
#!/bin/bash
while true; do
    clear
    echo "=== Z-PRO Webhook Server ==="
    curl -s http://localhost:8081/zpro/stats | jq .
    echo ""
    sudo supervisorctl status zpro-webhook
    sleep 5
done
```

---

## 🔄 Atualização

```bash
cd zpro-webhook-server
git pull
sudo cp app.py /home/zpro/webhook/
sudo supervisorctl restart zpro-webhook
```

---

## 📞 Suporte

- **Logs:** `/var/log/zpro-webhook.*.log`
- **Configuração:** `/etc/supervisor/conf.d/zpro-webhook.conf`
- **Nginx:** `/etc/nginx/sites-available/zpro-webhook`

---

## 📝 Licença

MIT License - Livre para uso comercial e pessoal.

---

**Servidor pronto para produção!** 🎉
