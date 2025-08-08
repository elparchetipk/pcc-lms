# Políticas de Ciberseguridad - PCC LMS

**Versión:** 2025-08-08  
**Target:** Deployment en VPS Hostinger  
**Nivel:** Producción

---

## 🛡️ ARQUITECTURA DE SEGURIDAD MULTICAPA

### Layer 1: Infraestructura (VPS/Hostinger)

#### 🔧 Hardening del Servidor

```bash
# Actualizaciones automáticas de seguridad
sudo apt update && sudo apt upgrade -y
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Firewall UFW configurado
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# SSH hardening
# /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
Port 2222  # Puerto no estándar
MaxAuthTries 3
ClientAliveInterval 300
```

#### 🔑 Gestión de Accesos

- **SSH**: Solo claves públicas, puerto no estándar
- **Users**: Principio de menor privilegio
- **Sudo**: Sin NOPASSWD para operaciones críticas

### Layer 2: Contenerización (Docker)

#### 🐳 Docker Security

```dockerfile
# Usuarios no-root en containers
FROM python:3.11-slim
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# Solo puertos necesarios
EXPOSE 8000

# Secrets via environment variables
ENV DATABASE_URL_FILE=/run/secrets/db_url
```

#### 🔐 Docker Compose Security

```yaml
version: '3.8'
services:
  auth-service:
    build: ./be/fastapi/auth-service
    user: '1000:1000'
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    secrets:
      - jwt_secret
      - db_password
```

### Layer 3: Red y API Gateway (Traefik)

#### 🌐 Traefik Security Configuration

```yaml
# Rate Limiting
http:
  middlewares:
    rate-limit:
      rateLimit:
        burst: 100
        average: 50

    rate-limit-strict:
      rateLimit:
        burst: 10
        average: 5

    # Security Headers
    security-headers:
      headers:
        browserXssFilter: true
        contentTypeNosniff: true
        frameDeny: true
        referrerPolicy: 'strict-origin-when-cross-origin'
        customRequestHeaders:
          X-Forwarded-Proto: 'https'
```

#### 🛡️ SSL/TLS Obligatorio

```yaml
# Redirect HTTP -> HTTPS
http:
  routers:
    http-catchall:
      rule: 'hostregexp(`{host:.+}`)'
      entrypoints:
        - 'web'
      middlewares:
        - 'redirect-to-https'

  middlewares:
    redirect-to-https:
      redirectScheme:
        scheme: 'https'
        permanent: true
```

### Layer 4: Aplicación

#### 🔐 Autenticación JWT

```python
# FastAPI auth implementation
from jose import JWTError, jwt
from passlib.context import CryptContext

# Configuración segura
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")  # 256-bit random
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 15
REFRESH_TOKEN_EXPIRE_DAYS = 7

# Password hashing
pwd_context = CryptContext(
    schemes=["argon2"],
    deprecated="auto",
    argon2__memory_cost=65536,  # 64MB
    argon2__time_cost=3,
    argon2__parallelism=1
)
```

#### 🛡️ Input Validation & Sanitization

```python
from pydantic import BaseModel, validator, Field
import bleach

class UserInput(BaseModel):
    email: str = Field(..., regex=r'^[^@]+@[^@]+\.[^@]+$')
    first_name: str = Field(..., min_length=1, max_length=50)

    @validator('first_name')
    def sanitize_name(cls, v):
        return bleach.clean(v, strip=True)
```

### Layer 5: Base de Datos

#### 🔒 PostgreSQL Security

```sql
-- Database-level security
CREATE ROLE app_user WITH LOGIN PASSWORD 'strong_password';
GRANT CONNECT ON DATABASE pcc_lms TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;

-- Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_policy ON users
  FOR ALL TO app_user
  USING (user_id = current_setting('app.current_user_id')::uuid);
```

---

## 🚨 PROTECCIÓN CONTRA ATAQUES ESPECÍFICOS

### 1. **Inyección SQL**

```python
# ❌ VULNERABLE
query = f"SELECT * FROM users WHERE email = '{email}'"

# ✅ SEGURO - Prepared statements
query = "SELECT * FROM users WHERE email = %s"
cursor.execute(query, (email,))
```

### 2. **XSS (Cross-Site Scripting)**

```python
# Content Security Policy
@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)
    response.headers["Content-Security-Policy"] = (
        "default-src 'self'; "
        "script-src 'self' 'unsafe-inline'; "
        "style-src 'self' 'unsafe-inline';"
    )
    return response
```

### 3. **CSRF (Cross-Site Request Forgery)**

```python
from fastapi_csrf_protect import CsrfProtect

@app.post("/api/v1/courses", dependencies=[Depends(csrf.validate_csrf)])
async def create_course(request: Request):
    pass
```

### 4. **DDoS y Rate Limiting**

```yaml
# Traefik rate limiting por IP
http:
  middlewares:
    ddos-protection:
      rateLimit:
        burst: 100
        average: 50
        sourceCriterion:
          ipStrategy:
            depth: 1
```

### 5. **Enumeración de Usuarios**

```python
# ❌ VULNERABLE - Revela si user existe
if not user_exists(email):
    raise HTTPException(400, "User not found")

# ✅ SEGURO - Respuesta genérica
if not authenticate_user(email, password):
    raise HTTPException(401, "Invalid credentials")
```

### 6. **Fuerza Bruta**

```python
# Rate limiting por usuario
@limiter.limit("5/minute")
@app.post("/api/v1/auth/login")
async def login(request: Request, credentials: LoginRequest):
    # Implementación con delays progresivos
    attempt_count = await get_failed_attempts(credentials.email)
    if attempt_count > 3:
        await asyncio.sleep(2 ** attempt_count)  # Exponential backoff
```

---

## 🔧 CONFIGURACIÓN PARA HOSTINGER VPS

### 1. **Nginx Reverse Proxy**

```nginx
# /etc/nginx/sites-available/pcc-lms
server {
    listen 80;
    server_name pcc-lms.com www.pcc-lms.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name pcc-lms.com www.pcc-lms.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/pcc-lms.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/pcc-lms.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;

    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Rate Limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=3r/m;

    location /api/v1/auth/login {
        limit_req zone=login burst=5 nodelay;
        proxy_pass http://localhost:8080;
    }

    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 2. **Let's Encrypt SSL**

```bash
# Instalación y configuración automática
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d pcc-lms.com -d www.pcc-lms.com

# Auto-renovación
sudo crontab -e
0 12 * * * /usr/bin/certbot renew --quiet
```

### 3. **Fail2Ban para IDS**

```ini
# /etc/fail2ban/jail.local
[nginx-limit-req]
enabled = true
filter = nginx-limit-req
action = iptables-multiport[name=ReqLimit, port="http,https", protocol=tcp]
logpath = /var/log/nginx/*error.log
findtime = 600
bantime = 7200
maxretry = 10

[nginx-auth]
enabled = true
filter = nginx-auth
action = iptables-multiport[name=NoAuthFailures, port="http,https", protocol=tcp]
logpath = /var/log/nginx/*access.log
findtime = 600
bantime = 7200
maxretry = 6
```

---

## 🔍 MONITOREO Y ALERTAS

### 1. **Logging Centralizado**

```yaml
# docker-compose.yml - logging
logging:
  driver: 'json-file'
  options:
    max-size: '100m'
    max-file: '3'
    labels: 'service,environment'
```

### 2. **Health Checks**

```python
# Endpoint de health con checks de seguridad
@app.get("/health")
async def health_check():
    checks = {
        "database": await check_db_connection(),
        "redis": await check_redis_connection(),
        "disk_space": check_disk_space() > 20,  # > 20% free
        "memory": check_memory_usage() < 80,    # < 80% used
    }

    if all(checks.values()):
        return {"status": "healthy", "checks": checks}
    else:
        raise HTTPException(503, {"status": "unhealthy", "checks": checks})
```

### 3. **Alertas de Seguridad**

```bash
# Script de monitoreo
#!/bin/bash
# /opt/pcc-lms/scripts/security-monitor.sh

# Check for suspicious activities
suspicious_ips=$(tail -n 1000 /var/log/nginx/access.log | grep -E "(401|403|404)" | cut -d' ' -f1 | sort | uniq -c | sort -nr | head -5)

# Check system resources
disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
memory_usage=$(free | grep Mem | awk '{printf("%.2f", $3/$2 * 100.0)}')

# Send alerts if thresholds exceeded
if [ "$disk_usage" -gt 90 ]; then
    echo "ALERT: Disk usage is ${disk_usage}%" | mail -s "PCC-LMS Disk Alert" admin@pcc-lms.com
fi
```

---

## 📋 CHECKLIST DE DEPLOYMENT SEGURO

### Pre-Deployment

- [ ] Secrets configurados (JWT_SECRET, DB_PASSWORD)
- [ ] Firewall UFW configurado y activo
- [ ] SSH hardening aplicado
- [ ] SSL/TLS certificados válidos
- [ ] Rate limiting configurado en Nginx/Traefik
- [ ] Fail2Ban instalado y configurado

### Post-Deployment

- [ ] Health checks funcionando
- [ ] Logs centralizados y monitoreados
- [ ] Backups automáticos configurados
- [ ] Alertas de seguridad activas
- [ ] Penetration testing básico realizado
- [ ] Documentación de incidentes preparada

### Mantenimiento Continuo

- [ ] Actualizaciones de seguridad automáticas
- [ ] Revisión mensual de logs de seguridad
- [ ] Rotación de secrets cada 90 días
- [ ] Auditoría de accesos trimestral
- [ ] Testing de disaster recovery semestral

---

## 🚨 PLAN DE RESPUESTA A INCIDENTES

### 1. **Detección**

- Monitoreo 24/7 de logs críticos
- Alertas automáticas por email/Slack
- Health checks cada 30 segundos

### 2. **Respuesta Inmediata**

```bash
# Emergency shutdown
docker-compose down
sudo ufw deny out 80,443

# Incident investigation
tail -f /var/log/nginx/access.log | grep -E "(401|403|404|5xx)"
docker logs pcc-lms_auth-service_1 --since 1h
```

### 3. **Comunicación**

- [ ] Notificar al equipo técnico (< 5 min)
- [ ] Evaluar impacto en usuarios (< 15 min)
- [ ] Comunicar a stakeholders si es crítico (< 30 min)

### 4. **Recuperación**

- [ ] Identificar y patchear vulnerabilidad
- [ ] Restaurar desde backup si es necesario
- [ ] Verificar integridad de datos
- [ ] Monitoreo intensivo post-recuperación

---

## 🔧 IMPLEMENTACIONES POR STACK TECNOLÓGICO

### 🐍 FastAPI (Python)

#### Autenticación y Autorización

```python
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer

# Password hashing con Argon2
pwd_context = CryptContext(
    schemes=["argon2"],
    deprecated="auto",
    argon2__memory_cost=65536,  # 64MB
    argon2__time_cost=3,
    argon2__parallelism=1
)

# JWT Security
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")  # 256-bit
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 15

async def get_current_user(token: str = Depends(HTTPBearer())):
    try:
        payload = jwt.decode(token.credentials, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
```

#### Input Validation

```python
from pydantic import BaseModel, validator, Field
import bleach

class UserCreate(BaseModel):
    email: EmailStr = Field(..., description="Valid email address")
    password: str = Field(..., min_length=12, regex=r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])')
    first_name: str = Field(..., min_length=1, max_length=50)

    @validator('first_name', 'last_name')
    def sanitize_text(cls, v):
        return bleach.clean(v.strip(), tags=[], strip=True)
```

### 🐹 Go

#### JWT y Middleware de Seguridad

```go
package security

import (
    "time"
    "github.com/golang-jwt/jwt/v4"
    "github.com/gin-gonic/gin"
    "golang.org/x/crypto/argon2"
)

// Password hashing con Argon2
func HashPassword(password string) (string, error) {
    salt := make([]byte, 16)
    rand.Read(salt)

    hash := argon2.IDKey([]byte(password), salt, 3, 64*1024, 1, 32)
    return base64.RawStdEncoding.EncodeToString(hash), nil
}

// JWT Middleware
func JWTMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        token := c.GetHeader("Authorization")
        if token == "" {
            c.JSON(401, gin.H{"error": "No token provided"})
            c.Abort()
            return
        }

        claims := &jwt.StandardClaims{}
        tkn, err := jwt.ParseWithClaims(token, claims, func(token *jwt.Token) (interface{}, error) {
            return []byte(os.Getenv("JWT_SECRET")), nil
        })

        if err != nil || !tkn.Valid {
            c.JSON(401, gin.H{"error": "Invalid token"})
            c.Abort()
            return
        }

        c.Set("user_id", claims.Subject)
        c.Next()
    }
}
```

#### Input Validation

```go
import (
    "github.com/go-playground/validator/v10"
    "html"
)

type UserInput struct {
    Email     string `json:"email" validate:"required,email"`
    FirstName string `json:"first_name" validate:"required,min=1,max=50"`
    Password  string `json:"password" validate:"required,min=12"`
}

func ValidateAndSanitize(input *UserInput) error {
    validate := validator.New()
    if err := validate.Struct(input); err != nil {
        return err
    }

    // Sanitización
    input.FirstName = html.EscapeString(strings.TrimSpace(input.FirstName))
    return nil
}
```

### 🟨 Express.js (Node.js)

#### Middleware de Seguridad

```javascript
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const validator = require('validator');

// Security middleware
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", 'data:', 'https:'],
      },
    },
  })
);

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests, please try again later',
});
app.use('/api/', limiter);

// Password hashing
const saltRounds = 12;
const hashPassword = async (password) => {
  return await bcrypt.hash(password, saltRounds);
};

// JWT Authentication
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.sendStatus(401);
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};
```

#### Input Validation y Sanitización

```javascript
const { body, validationResult } = require('express-validator');
const DOMPurify = require('isomorphic-dompurify');

// Validation middleware
const validateUser = [
  body('email').isEmail().normalizeEmail(),
  body('password')
    .isLength({ min: 12 })
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/),
  body('firstName').trim().isLength({ min: 1, max: 50 }).escape(),

  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    // Sanitización adicional
    req.body.firstName = DOMPurify.sanitize(req.body.firstName);
    next();
  },
];
```

### ⚛️ Next.js

#### API Routes Security

```javascript
// pages/api/auth/login.js
import { NextApiRequest, NextApiResponse } from 'next';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import rateLimit from 'express-rate-limit';

// Rate limiting para API routes
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // 5 attempts per IP per window
});

// CSRF Protection
import { getCsrfToken } from 'next-auth/csrf';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  // Method validation
  if (req.method !== 'POST') {
    return res.status(405).json({ message: 'Method not allowed' });
  }

  // Rate limiting
  await limiter(req, res, () => {});

  // CSRF validation
  const csrfToken = await getCsrfToken({ req });
  if (req.body.csrfToken !== csrfToken) {
    return res.status(403).json({ message: 'Invalid CSRF token' });
  }

  // Input validation
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: 'Missing credentials' });
  }

  // Authentication logic...
}
```

#### Client-Side Security

```javascript
// components/SecurityHeaders.js
import Head from 'next/head';

export default function SecurityHeaders() {
  return (
    <Head>
      <meta
        httpEquiv="Content-Security-Policy"
        content="default-src 'self'; script-src 'self' 'unsafe-eval'; style-src 'self' 'unsafe-inline';"
      />
      <meta
        httpEquiv="X-Content-Type-Options"
        content="nosniff"
      />
      <meta
        httpEquiv="X-Frame-Options"
        content="DENY"
      />
      <meta
        httpEquiv="X-XSS-Protection"
        content="1; mode=block"
      />
    </Head>
  );
}
```

### ☕ Spring Boot (Java)

#### Security Configuration

```java
@Configuration
@EnableWebSecurity
@EnableGlobalMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    @Autowired
    private JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }

    @Bean
    public JwtAuthenticationFilter jwtAuthenticationFilter() {
        return new JwtAuthenticationFilter();
    }

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.csrf().disable()
            .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
            .authorizeRequests()
                .antMatchers("/api/auth/**").permitAll()
                .anyRequest().authenticated()
            .and()
            .exceptionHandling().authenticationEntryPoint(jwtAuthenticationEntryPoint)
            .and()
            .addFilterBefore(jwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class);

        // Security headers
        http.headers()
            .frameOptions().deny()
            .contentTypeOptions().and()
            .httpStrictTransportSecurity(hstsConfig ->
                hstsConfig.maxAgeInSeconds(31536000).includeSubdomains(true));
    }
}
```

#### Input Validation

```java
@Entity
@Table(name = "users")
public class User {

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    @Column(unique = true)
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 12, message = "Password must be at least 12 characters")
    @Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])",
             message = "Password must contain uppercase, lowercase, digit and special character")
    private String password;

    @NotBlank(message = "First name is required")
    @Size(max = 50, message = "First name cannot exceed 50 characters")
    private String firstName;
}

@RestController
@Validated
public class UserController {

    @PostMapping("/api/users")
    public ResponseEntity<User> createUser(@Valid @RequestBody User user) {
        // Sanitización
        user.setFirstName(StringEscapeUtils.escapeHtml4(user.getFirstName().trim()));

        // Process user creation...
        return ResponseEntity.ok(userService.create(user));
    }
}
```

### 🔮 Spring Boot (Kotlin)

#### Security Configuration

```kotlin
@Configuration
@EnableWebSecurity
@EnableGlobalMethodSecurity(prePostEnabled = true)
class SecurityConfig {

    @Bean
    fun passwordEncoder(): PasswordEncoder = BCryptPasswordEncoder(12)

    @Bean
    fun jwtAuthenticationFilter() = JwtAuthenticationFilter()

    @Throws(Exception::class)
    fun configure(http: HttpSecurity) {
        http.csrf().disable()
            .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
            .authorizeRequests {
                it.antMatchers("/api/auth/**").permitAll()
                  .anyRequest().authenticated()
            }
            .exceptionHandling().authenticationEntryPoint(jwtAuthenticationEntryPoint)
            .and()
            .addFilterBefore(jwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter::class.java)

        // Security headers
        http.headers {
            it.frameOptions().deny()
              .contentTypeOptions()
              .httpStrictTransportSecurity { hstsConfig ->
                  hstsConfig.maxAgeInSeconds(31536000).includeSubdomains(true)
              }
        }
    }
}
```

#### Data Classes con Validación

```kotlin
@Entity
@Table(name = "users")
data class User(
    @field:NotBlank(message = "Email is required")
    @field:Email(message = "Invalid email format")
    @Column(unique = true)
    val email: String,

    @field:NotBlank(message = "Password is required")
    @field:Size(min = 12, message = "Password must be at least 12 characters")
    @field:Pattern(
        regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])",
        message = "Password must contain uppercase, lowercase, digit and special character"
    )
    val password: String,

    @field:NotBlank(message = "First name is required")
    @field:Size(max = 50, message = "First name cannot exceed 50 characters")
    val firstName: String
)

@RestController
@Validated
class UserController {

    @PostMapping("/api/users")
    fun createUser(@Valid @RequestBody user: User): ResponseEntity<User> {
        // Sanitización
        val sanitizedUser = user.copy(
            firstName = StringEscapeUtils.escapeHtml4(user.firstName.trim())
        )

        return ResponseEntity.ok(userService.create(sanitizedUser))
    }
}
```

---

## 🎯 CONFIGURACIONES ESPECÍFICAS POR STACK

### Dependencias de Seguridad por Tecnología

#### FastAPI (Python)

```bash
pip install passlib[argon2] python-jose[cryptography] python-multipart
pip install fastapi-csrf-protect python-decouple bleach
```

#### Go

```bash
go get github.com/golang-jwt/jwt/v4
go get golang.org/x/crypto/argon2
go get github.com/gin-contrib/secure
```

#### Express.js

```bash
npm install helmet express-rate-limit bcrypt jsonwebtoken
npm install express-validator isomorphic-dompurify cors
```

#### Next.js

```bash
npm install next-auth bcryptjs jsonwebtoken
npm install @types/bcryptjs @types/jsonwebtoken
```

#### Spring Boot (Java/Kotlin)

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt</artifactId>
    <version>0.11.5</version>
</dependency>
```

---

## 🐳 CONFIGURACIONES DOCKER SEGURAS POR STACK

### FastAPI (Python)

```dockerfile
FROM python:3.11-slim

# Crear usuario no-root
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Instalar dependencias de sistema
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Configurar directorio de trabajo
WORKDIR /app

# Copiar requirements e instalar dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copiar código fuente
COPY --chown=appuser:appuser . .

# Cambiar a usuario no-root
USER appuser

# Exponer puerto
EXPOSE 8000

# Comando de inicio
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Go

```dockerfile
FROM golang:1.21-alpine AS builder

# Instalar ca-certificates para HTTPS
RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copiar go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copiar código fuente
COPY . .

# Build del binario
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage
FROM scratch

# Copiar ca-certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copiar binario
COPY --from=builder /app/main /main

# Exponer puerto
EXPOSE 8080

# Usuario no-root (scratch no tiene usuarios, se configura en compose)
CMD ["/main"]
```

### Express.js (Node.js)

```dockerfile
FROM node:22.18-alpine

# Crear usuario no-root
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Configurar directorio de trabajo
WORKDIR /app

# Copiar package.json y package-lock.json
COPY package*.json ./

# Instalar dependencias
RUN npm ci --only=production && npm cache clean --force

# Copiar código fuente
COPY --chown=nextjs:nodejs . .

# Cambiar a usuario no-root
USER nextjs

# Exponer puerto
EXPOSE 3000

# Comando de inicio
CMD ["npm", "start"]
```

### Next.js

```dockerfile
FROM node:22.18-alpine AS base

# Instalar dependencias
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

# Build de la aplicación
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED 1
RUN npm run build

# Production stage
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
```

### Spring Boot (Java)

```dockerfile
FROM openjdk:17-jdk-slim AS builder

WORKDIR /app

# Copiar archivos de configuración
COPY pom.xml .
COPY src ./src

# Build de la aplicación
RUN ./mvnw clean package -DskipTests

# Production stage
FROM openjdk:17-jre-slim

# Crear usuario no-root
RUN groupadd -r spring && useradd -r -g spring spring

# Configurar directorio de trabajo
WORKDIR /app

# Copiar JAR desde builder stage
COPY --from=builder --chown=spring:spring /app/target/*.jar app.jar

# Cambiar a usuario no-root
USER spring

# Exponer puerto
EXPOSE 8080

# Configuraciones de JVM para seguridad
ENV JAVA_OPTS="-Xmx512m -Xms256m -Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"

# Comando de inicio
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

### Spring Boot (Kotlin)

```dockerfile
FROM openjdk:17-jdk-slim AS builder

WORKDIR /app

# Copiar archivos de configuración
COPY build.gradle.kts settings.gradle.kts ./
COPY gradle ./gradle
COPY gradlew ./
COPY src ./src

# Build de la aplicación
RUN ./gradlew build --no-daemon

# Production stage
FROM openjdk:17-jre-slim

# Crear usuario no-root
RUN groupadd -r spring && useradd -r -g spring spring

WORKDIR /app

# Copiar JAR desde builder stage
COPY --from=builder --chown=spring:spring /app/build/libs/*.jar app.jar

USER spring

EXPOSE 8080

ENV JAVA_OPTS="-Xmx512m -Xms256m -Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"

CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

---

## 🔒 VARIABLES DE ENTORNO SEGURAS POR STACK

### Configuración Común (.env)

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/pcc_lms
DATABASE_POOL_SIZE=10
DATABASE_TIMEOUT=30

# JWT Security
JWT_SECRET_KEY=your-super-secret-256-bit-key-here
JWT_ALGORITHM=HS256
JWT_ACCESS_EXPIRE=900    # 15 minutes
JWT_REFRESH_EXPIRE=604800 # 7 days

# Redis Cache
REDIS_URL=redis://localhost:6379/0
REDIS_PASSWORD=your-redis-password

# Rate Limiting
RATE_LIMIT_WINDOW=900    # 15 minutes
RATE_LIMIT_MAX=100       # requests per window

# CORS
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Email (si aplica)
SMTP_HOST=smtp.hostinger.com
SMTP_PORT=587
SMTP_USER=noreply@yourdomain.com
SMTP_PASSWORD=your-smtp-password
```

### FastAPI Específico

```bash
# FastAPI Settings
DEBUG=False
TESTING=False
SECRET_KEY=your-app-secret-key
ALGORITHM=HS256

# CORS
BACKEND_CORS_ORIGINS=["https://yourdomain.com"]

# Security
ARGON2_MEMORY_COST=65536
ARGON2_TIME_COST=3
ARGON2_PARALLELISM=1
```

### Go Específico

```bash
# Go App Settings
GIN_MODE=release
APP_ENV=production
LOG_LEVEL=info

# Server
SERVER_PORT=8080
SERVER_READ_TIMEOUT=10
SERVER_WRITE_TIMEOUT=10
```

### Express.js Específico

```bash
# Node.js Settings
NODE_ENV=production
PORT=3000

# Session Security
SESSION_SECRET=your-session-secret-key
COOKIE_SECURE=true
COOKIE_HTTP_ONLY=true
COOKIE_SAME_SITE=strict
```

### Next.js Específico

```bash
# Next.js Settings
NEXTAUTH_URL=https://yourdomain.com
NEXTAUTH_SECRET=your-nextauth-secret-key

# API Settings
API_BASE_URL=https://api.yourdomain.com
```

### Spring Boot Específico

```bash
# Spring Boot Settings
SPRING_PROFILES_ACTIVE=production

# Security
SPRING_SECURITY_PASSWORD_STRENGTH=12

# Logging
LOGGING_LEVEL_ROOT=INFO
LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_SECURITY=INFO
```

---

### 📦 Gestión de Dependencias: PNPM vs NPM

#### ✅ **PNPM como Estándar (RECOMENDADO)**

**Decisión técnica:** PCC LMS utiliza **PNPM** exclusivamente para gestión de paquetes Node.js.

#### 🔐 **Ventajas de Seguridad de PNPM**

##### 1. **Resolución de Dependencias Estricta**

```bash
# PNPM previene hoisting problemático
# Cada paquete accede SOLO a sus dependencias declaradas
pnpm install  # ✅ Estructura aislada
npm install   # ❌ Hoisting puede crear vulnerabilidades
```

##### 2. **Espacio de Disco y Performance**

```bash
# PNPM: Hard links + store global
$ pnpm install
# 🚀 70% menos espacio en disco
# 🚀 2x más rápido que npm
# 🛡️ Menos superficie de ataque (menos duplicados)

# NPM: Duplicación en cada node_modules
$ npm install
# ❌ Duplicación masiva
# ❌ Más lento
# ❌ Mayor superficie de ataque
```

##### 3. **Integrity Checking Robusto**

```bash
# PNPM verifica integridad más estrictamente
pnpm install --frozen-lockfile  # ✅ Verificación SHA estricta
npm ci                          # ⚠️ Menos verificaciones
```

##### 4. **Reproducibilidad Garantizada**

```json
// pnpm-lock.yaml más determinista que package-lock.json
{
  "lockfileVersion": 6.0,
  "integrity": "sha512-...", // ✅ Más información de integridad
  "dependencies": {
    // Estructura más clara y verificable
  }
}
```

#### 🚨 **Vulnerabilidades Específicas de NPM**

##### 1. **Dependency Confusion**

```bash
# NPM: Hoisting puede causar confusión de dependencias
node_modules/
├── package-a/
└── malicious-package/  # ❌ Accesible desde package-a

# PNPM: Estructura aislada previene esto
.pnpm/
├── package-a@1.0.0/
│   └── node_modules/package-a/  # ✅ Solo acceso a lo declarado
└── malicious-package@1.0.0/     # ✅ Aislado
```

##### 2. **Supply Chain Attacks**

```bash
# PNPM: Verificación más robusta
pnpm audit             # ✅ Auditoría comprehensiva
pnpm audit --fix       # ✅ Fixes seguros

# NPM: Auditoría menos confiable
npm audit              # ⚠️ Puede perder vulnerabilidades
npm audit fix          # ❌ Puede romper dependencias
```

#### 🛠️ **Implementación Segura**

##### 1. **Configuración .pnpmrc**

```ini
# .pnpmrc - Configuración de seguridad
strict-peer-dependencies=true
auto-install-peers=false
enable-pre-post-scripts=false
registry=https://registry.npmjs.org/
verify-store-integrity=true
side-effects-cache=false
```

##### 2. **Scripts de Seguridad**

```json
// package.json
{
  "scripts": {
    "security:audit": "pnpm audit",
    "security:update": "pnpm update --latest",
    "security:check": "pnpm outdated",
    "security:clean": "pnpm store prune"
  }
}
```

##### 3. **CI/CD con PNPM**

```yaml
# .github/workflows/security.yml
- name: Setup PNPM
  uses: pnpm/action-setup@v2
  with:
    version: latest

- name: Install dependencies
  run: pnpm install --frozen-lockfile

- name: Security audit
  run: pnpm audit --audit-level moderate
```

#### 📊 **Comparativa de Seguridad**

| Aspecto             | PNPM             | NPM                      | Justificación                      |
| ------------------- | ---------------- | ------------------------ | ---------------------------------- |
| **Isolation**       | ✅ Estricto      | ❌ Hoisting problemático | PNPM previene dependency confusion |
| **Integrity**       | ✅ SHA + content | ⚠️ Solo SHA              | PNPM verifica contenido también    |
| **Reproducibility** | ✅ Determinista  | ⚠️ Variable              | pnpm-lock.yaml más confiable       |
| **Audit Quality**   | ✅ Comprehensivo | ⚠️ Limitado              | PNPM detecta más vulnerabilidades  |
| **Performance**     | ✅ 2x más rápido | ❌ Lento                 | Menos tiempo de exposición         |
| **Disk Usage**      | ✅ 70% menos     | ❌ Duplicación           | Menor superficie de ataque         |

#### 🎯 **Reglas de Implementación**

##### 1. **Prohibiciones**

```bash
# ❌ PROHIBIDO en el proyecto
npm install    # Usar: pnpm install
npm ci         # Usar: pnpm install --frozen-lockfile
npm run        # Usar: pnpm run
npm update     # Usar: pnpm update
```

##### 2. **Comandos Obligatorios**

```bash
# ✅ COMANDOS ESTÁNDAR
pnpm install --frozen-lockfile  # En CI/CD
pnpm audit                      # Antes de cada deploy
pnpm outdated                   # Revisión semanal
pnpm store prune               # Limpieza mensual
```

##### 3. **Verificación de Integridad**

```bash
# Verificar antes de cada release
pnpm audit --audit-level moderate
pnpm outdated --format table
pnpm why suspicious-package  # Investigar dependencias
```

#### 🔒 **Integración con DevSecOps**

```yaml
# docker-compose.yml - PNPM en containers
services:
  frontend:
    build:
      dockerfile: Dockerfile
      args:
        - PACKAGE_MANAGER=pnpm
    environment:
      - PNPM_HOME=/usr/local/bin
```

```dockerfile
# Dockerfile con PNPM
FROM node:22.18-alpine
RUN npm install -g pnpm@latest
COPY pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --production
```
