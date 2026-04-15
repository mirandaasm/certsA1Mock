# certsA1Mock 🔐

Ferramenta para geração de **Certificados Digitais A1 mockados** (arquivo `.pfx`) para testes e validação de aplicações que processam certificados digitais — incluindo suporte a **CNPJ alfanumérico** (novo formato Receita Federal).

> ⚠️ **Aviso:** Os certificados gerados são **autoassinados** e destinados **exclusivamente para testes**. Não possuem validade jurídica nem são emitidos por uma AC credenciada pela ICP-Brasil.

---

## 📋 Pré-requisitos

**OpenSSL** instalado e disponível no PATH do Windows.

```powershell
# Instalar via winget (recomendado)
winget install ShiningLight.OpenSSL.Light
```

Após instalar, feche e reabra o terminal para que o `openssl` esteja no PATH.

---

## 📁 Estrutura do Repositório

```
certsA1Mock/
├── gerar_cert_a1_mock.ps1           ← Ferramenta principal
├── configs/                          ← Arquivos .cnf (um por CNPJ)
│   ├── _TEMPLATE_cert_config.cnf    ← Template para novos CNPJs
│   └── cert_config_02G0NC3Z000173.cnf
├── output/                           ← PFX gerados (ignorado pelo Git)
└── temp/                             ← Arquivos intermediários (ignorado pelo Git)
```

---

## 🚀 Como Usar

### Uso rápido — gerar certificado para um CNPJ já configurado

```powershell
.\gerar_cert_a1_mock.ps1 -Cnpj 02G0NC3Z000173
```

### Criar certificado para um NOVO CNPJ

```powershell
# 1. Copiar o template
Copy-Item "configs\_TEMPLATE_cert_config.cnf" "configs\cert_config_SEUCNPJ.cnf"

# 2. Editar o arquivo (substituir os {PLACEHOLDERS})
notepad "configs\cert_config_SEUCNPJ.cnf"

# 3. Gerar!
.\gerar_cert_a1_mock.ps1 -Cnpj SEUCNPJ
```

### Parâmetros opcionais

```powershell
# Senha customizada
.\gerar_cert_a1_mock.ps1 -Cnpj 02G0NC3Z000173 -Senha "OutraSenha!456"

# Validade de 2 anos
.\gerar_cert_a1_mock.ps1 -Cnpj 02G0NC3Z000173 -ValidadeDias 730

# Tudo junto
.\gerar_cert_a1_mock.ps1 -Cnpj 02G0NC3Z000173 -Senha "Teste@2026" -ValidadeDias 90
```

### Regenerar (sobrescreve automaticamente)

```powershell
# Simplesmente rode de novo — o PFX antigo é removido automaticamente
.\gerar_cert_a1_mock.ps1 -Cnpj 02G0NC3Z000173
```

---

## 📐 Convenção de Nomes

| Artefato | Padrão de Nome | Exemplo |
|---|---|---|
| **Config** | `configs/cert_config_{CNPJ}.cnf` | `cert_config_02G0NC3Z000173.cnf` |
| **PFX** | `output/cert_a1_mock_{CNPJ}.pfx` | `cert_a1_mock_02G0NC3Z000173.pfx` |
| **Chave** (temp) | `temp/cert_a1_mock_{CNPJ}.key` | Removido automaticamente |
| **Cert** (temp) | `temp/cert_a1_mock_{CNPJ}.crt` | Removido automaticamente |

> O CNPJ sempre em **letras maiúsculas**, **sem pontuação** (sem `.`, `/` ou `-`).

---

## 🔍 Dados Embarcados no Certificado (OIDs ICP-Brasil simulados)

| OID | Descrição | Exemplo |
|---|---|---|
| `2.16.76.1.3.3` | CNPJ do titular | `02G0NC3Z000173` |
| `2.16.76.1.3.1` | DataNasc + CPF + NIS + RG do responsável | `00000000093427717690000...` |
| `2.16.76.1.3.4` | Nome do responsável | `Anderson Silva de Miranda` |
| `2.16.76.1.3.6` | CEP do titular | `02341001` |
| `2.16.76.1.3.2` | Nome do responsável (redundância ICP-Brasil) | `Anderson Silva de Miranda` |
| `2.16.76.1.3.7` | Endereço completo | `Avenida Nova Cantareira 3443...` |

---

## 💡 Dicas

- Versione os arquivos `configs/*.cnf` no Git para manter um **cadastro** dos certificados de teste.
- As pastas `output/` e `temp/` estão no `.gitignore` — os PFX **não são versionados** (contêm chaves privadas).
- O script é idempotente: rodar duas vezes para o mesmo CNPJ **sobrescreve** o PFX anterior.
- CNPJ alfanumérico: letras são tratadas normalmente na string de 14 caracteres.

---

## 📖 Exemplo de Leitura do PFX

### Java
```java
KeyStore ks = KeyStore.getInstance("PKCS12");
try (FileInputStream fis = new FileInputStream("cert_a1_mock_02G0NC3Z000173.pfx")) {
    ks.load(fis, "Iob@2026".toCharArray());
}
X509Certificate cert = (X509Certificate) ks.getCertificate(ks.aliases().nextElement());
System.out.println("Subject: " + cert.getSubjectX500Principal().getName());
```

### C# / .NET
```csharp
var cert = new X509Certificate2("cert_a1_mock_02G0NC3Z000173.pfx", "Iob@2026");
Console.WriteLine($"Subject: {cert.Subject}");
```

### Python
```python
from cryptography.hazmat.primitives.serialization import pkcs12
with open("cert_a1_mock_02G0NC3Z000173.pfx", "rb") as f:
    private_key, certificate, _ = pkcs12.load_key_and_certificates(f.read(), b"Iob@2026")
print(certificate.subject)
```

---

## 📜 Licença

MIT — livre para uso em ambientes de desenvolvimento e testes.
