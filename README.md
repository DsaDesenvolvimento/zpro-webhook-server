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

- **Dashboard:** http://217.196.63.63/
- **Health Check:** http://217.196.63.63/health
- **Conversas Ativas:** http://217.196.63.63/zpro/active
- **Estatísticas:** http://217.196.63.63/zpro/stats

### Webhooks (configure no Z-PRO):

- **Messages:** http://217.196.63.63/zpro/webhook/messages
- **Status:** http://217.196.63.63/zpro/webhook/status

---

## 🔧 Configurar Z-PRO

1. Acesse painel Automatix: https://zproapi.automatix.global
2. Vá em **API > Webhooks**
3. Configure:
   - **Message Webhook:** `http://217.196.63.63/zpro/webhook/messages`
   - **Status Webhook:** `http://217.196.63.63/zpro/webhook/status`

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

**Servidor pronto para produção!** 🎉
