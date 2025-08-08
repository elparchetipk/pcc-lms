# Plan de Desarrollo - PCC LMS Stack Go

> 🚀 **Stack Principal**: Go + PostgreSQL + Redis + React  
> 🎯 **Target**: Producción con máxima performance y seguridad  
> 📅 **Timeline**: 12 semanas para MVP funcional  
> 💰 **Budget**: Solopreneur-friendly con escalamiento inteligente

## 🎯 Por Qué Go es la Elección Correcta

### ✅ **Ventajas para LMS en Producción**

```yaml
performance:
  - Concurrencia nativa (goroutines)
  - Latencia ultra-baja (<1ms)
  - Memory efficiency excepcional
  - Garbage collector optimizado

scalability:
  - Handle 10K+ usuarios concurrentes
  - Microservicios ligeros
  - Deployment sencillo (binary único)
  - Horizontal scaling natural

security:
  - Type safety estricto
  - Memory safety built-in
  - Crypto library robusta
  - Vulnerabilidades mínimas

devops:
  - Docker images ultra-pequeñas (5-10MB)
  - Hot reload en desarrollo
  - Cross-compilation fácil
  - Monitoring y profiling built-in
```

### 🏆 **Go vs Otras Opciones**

```yaml
go_vs_node:
  performance: 'Go 3-5x más rápido'
  memory: 'Go 50% menos RAM'
  concurrency: 'Go goroutines vs Node event loop'
  deployment: 'Go binary vs Node dependencies'

go_vs_python:
  performance: 'Go 10-50x más rápido'
  typing: 'Go compilado vs Python interpretado'
  deployment: 'Go binary vs Python environment'
  scalability: 'Go concurrency vs Python GIL'

go_vs_java:
  startup: 'Go instantáneo vs Java JVM warmup'
  memory: 'Go menor footprint'
  complexity: 'Go simplicidad vs Java verbosity'
  deployment: 'Go binary vs Java JAR+JVM'
```

---

## 📋 Plan de Desarrollo - 12 Semanas

### **Semana 1-2: Fundación y Arquitectura**

#### Objetivos

- [x] Setup del workspace Go
- [x] Arquitectura Clean Architecture
- [x] Base de datos y migraciones
- [x] Authentication básico

#### Deliverables

```bash
📁 be/go/
├── cmd/
│   └── server/
│       └── main.go                 # Entry point
├── internal/
│   ├── auth/                       # Authentication service
│   │   ├── domain/
│   │   ├── repository/
│   │   ├── usecase/
│   │   └── handler/
│   ├── user/                       # User management
│   └── shared/                     # Shared utilities
├── pkg/
│   ├── database/                   # DB connection
│   ├── middleware/                 # HTTP middlewares
│   └── security/                   # Security utilities
├── migrations/
├── docker-compose.yml
├── Dockerfile
└── go.mod
```

#### Código Base Semana 1-2

```go
// cmd/server/main.go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/pcc-lms/internal/auth"
    "github.com/pcc-lms/internal/user"
    "github.com/pcc-lms/pkg/database"
    "github.com/pcc-lms/pkg/middleware"
)

func main() {
    // Database connection
    db, err := database.NewPostgresConnection()
    if err != nil {
        log.Fatal("Failed to connect to database:", err)
    }
    defer db.Close()

    // Initialize services
    userRepo := user.NewRepository(db)
    userUsecase := user.NewUsecase(userRepo)
    userHandler := user.NewHandler(userUsecase)

    authUsecase := auth.NewUsecase(userRepo)
    authHandler := auth.NewHandler(authUsecase)

    // Setup routes
    r := gin.Default()
    r.Use(middleware.CORS())
    r.Use(middleware.SecurityHeaders())
    r.Use(middleware.RateLimit())

    api := r.Group("/api/v1")
    {
        // Authentication
        auth := api.Group("/auth")
        {
            auth.POST("/register", authHandler.Register)
            auth.POST("/login", authHandler.Login)
            auth.POST("/refresh", authHandler.RefreshToken)
        }

        // Protected routes
        protected := api.Group("/")
        protected.Use(middleware.JWTAuth())
        {
            protected.GET("/profile", userHandler.GetProfile)
            protected.PUT("/profile", userHandler.UpdateProfile)
        }
    }

    // Graceful shutdown
    srv := &http.Server{
        Addr:    ":8080",
        Handler: r,
    }

    go func() {
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("Server failed to start: %v", err)
        }
    }()

    // Wait for interrupt signal
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, os.Interrupt)
    <-quit

    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    if err := srv.Shutdown(ctx); err != nil {
        log.Fatal("Server forced to shutdown:", err)
    }
}
```

### **Semana 3-4: Core Business Logic**

#### Objetivos

- [x] Course management
- [x] Content management
- [x] Enrollment system
- [x] Progress tracking

#### Servicios a Implementar

```go
// internal/course/domain/course.go
type Course struct {
    ID          uuid.UUID `json:"id" db:"id"`
    Title       string    `json:"title" db:"title"`
    Description string    `json:"description" db:"description"`
    InstructorID uuid.UUID `json:"instructor_id" db:"instructor_id"`
    Price       float64   `json:"price" db:"price"`
    Currency    string    `json:"currency" db:"currency"`
    Status      string    `json:"status" db:"status"`
    CreatedAt   time.Time `json:"created_at" db:"created_at"`
    UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

// internal/content/domain/content.go
type Content struct {
    ID       uuid.UUID `json:"id" db:"id"`
    CourseID uuid.UUID `json:"course_id" db:"course_id"`
    Title    string    `json:"title" db:"title"`
    Type     string    `json:"type" db:"type"` // video, text, quiz
    Data     string    `json:"data" db:"data"` // JSON content
    Order    int       `json:"order" db:"order"`
    Duration int       `json:"duration" db:"duration"` // seconds
}

// internal/enrollment/domain/enrollment.go
type Enrollment struct {
    ID           uuid.UUID  `json:"id" db:"id"`
    UserID       uuid.UUID  `json:"user_id" db:"user_id"`
    CourseID     uuid.UUID  `json:"course_id" db:"course_id"`
    Status       string     `json:"status" db:"status"`
    Progress     float64    `json:"progress" db:"progress"`
    EnrolledAt   time.Time  `json:"enrolled_at" db:"enrolled_at"`
    CompletedAt  *time.Time `json:"completed_at" db:"completed_at"`
}
```

### **Semana 5-6: Video Protection & Security** ⭐

#### Objetivos (Aplicando documentación de seguridad)

- [x] Implementar stack de protección de videos
- [x] Token system ultra-seguro
- [x] Watermarking dinámico
- [x] Rate limiting inteligente

#### Video Protection Service

```go
// internal/video/domain/video.go
package domain

import (
    "time"
    "github.com/google/uuid"
)

type Video struct {
    ID          uuid.UUID `json:"id" db:"id"`
    ContentID   uuid.UUID `json:"content_id" db:"content_id"`
    FilePath    string    `json:"file_path" db:"file_path"`
    Duration    int       `json:"duration" db:"duration"`
    Quality     string    `json:"quality" db:"quality"`
    Size        int64     `json:"size" db:"size"`
    Status      string    `json:"status" db:"status"`
    EncryptedPath string  `json:"encrypted_path" db:"encrypted_path"`
    CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

type StreamToken struct {
    UserID          uuid.UUID `json:"user_id"`
    VideoID         uuid.UUID `json:"video_id"`
    ExpiresAt       time.Time `json:"expires_at"`
    MaxViews        int       `json:"max_views"`
    DeviceFingerprint string  `json:"device_fingerprint"`
    IPAddress       string    `json:"ip_address"`
    Nonce           string    `json:"nonce"`
}

// internal/video/usecase/security.go
package usecase

import (
    "crypto/aes"
    "crypto/cipher"
    "crypto/rand"
    "crypto/sha256"
    "encoding/hex"
    "fmt"
    "io"
    "time"

    "github.com/golang-jwt/jwt/v5"
    "github.com/google/uuid"
)

type VideoSecurityUsecase struct {
    secretKey []byte
    usedTokens map[string]time.Time
}

func NewVideoSecurityUsecase() *VideoSecurityUsecase {
    return &VideoSecurityUsecase{
        secretKey: []byte("your-super-secret-key-32-bytes!!"),
        usedTokens: make(map[string]time.Time),
    }
}

// Generar token de streaming seguro
func (v *VideoSecurityUsecase) GenerateStreamToken(userID, videoID uuid.UUID, deviceFingerprint, ipAddress string) (string, error) {
    claims := jwt.MapClaims{
        "user_id":            userID.String(),
        "video_id":           videoID.String(),
        "expires_at":         time.Now().Add(10 * time.Minute).Unix(),
        "max_views":          1,
        "device_fingerprint": deviceFingerprint,
        "ip_address":         ipAddress,
        "nonce":              generateNonce(),
        "iat":                time.Now().Unix(),
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString(v.secretKey)
}

// Validar token (single-use)
func (v *VideoSecurityUsecase) ValidateStreamToken(tokenString string, deviceFingerprint, ipAddress string) (*StreamToken, error) {
    // Verificar si ya fue usado
    if _, used := v.usedTokens[tokenString]; used {
        return nil, fmt.Errorf("token already used")
    }

    token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
        return v.secretKey, nil
    })

    if err != nil {
        return nil, err
    }

    claims, ok := token.Claims.(jwt.MapClaims)
    if !ok || !token.Valid {
        return nil, fmt.Errorf("invalid token")
    }

    // Validar device fingerprint
    if claims["device_fingerprint"] != deviceFingerprint {
        return nil, fmt.Errorf("device mismatch")
    }

    // Validar IP (opcional, por si cambia por VPN)
    if claims["ip_address"] != ipAddress {
        // Log para análisis de seguridad pero no rechazar automáticamente
        logSecurityEvent("ip_mismatch", claims, ipAddress)
    }

    // Marcar token como usado
    v.usedTokens[tokenString] = time.Now()

    // Limpiar tokens expirados cada hora
    go v.cleanExpiredTokens()

    return &StreamToken{
        UserID:            uuid.MustParse(claims["user_id"].(string)),
        VideoID:           uuid.MustParse(claims["video_id"].(string)),
        DeviceFingerprint: claims["device_fingerprint"].(string),
        IPAddress:         claims["ip_address"].(string),
    }, nil
}

// Encriptar segmentos de video
func (v *VideoSecurityUsecase) EncryptVideoSegment(data []byte, userID uuid.UUID) ([]byte, error) {
    // Key derivation específica por usuario
    userKey := v.deriveUserKey(userID)

    block, err := aes.NewCipher(userKey)
    if err != nil {
        return nil, err
    }

    gcm, err := cipher.NewGCM(block)
    if err != nil {
        return nil, err
    }

    nonce := make([]byte, gcm.NonceSize())
    if _, err = io.ReadFull(rand.Reader, nonce); err != nil {
        return nil, err
    }

    ciphertext := gcm.Seal(nonce, nonce, data, nil)
    return ciphertext, nil
}

func (v *VideoSecurityUsecase) deriveUserKey(userID uuid.UUID) []byte {
    // Key rotation cada hora
    hourly := time.Now().Hour()
    data := fmt.Sprintf("%s:%d", userID.String(), hourly)
    hash := sha256.Sum256([]byte(data + string(v.secretKey)))
    return hash[:]
}

func generateNonce() string {
    bytes := make([]byte, 16)
    rand.Read(bytes)
    return hex.EncodeToString(bytes)
}
```

### **Semana 7-8: Advanced Features**

#### Objetivos

- [x] Payment integration (Stripe)
- [x] Real-time notifications
- [x] Assignment & Grading system
- [x] Analytics básicos

#### Payment Service

```go
// internal/payment/usecase/stripe.go
package usecase

import (
    "github.com/stripe/stripe-go/v74"
    "github.com/stripe/stripe-go/v74/paymentintent"
    "github.com/stripe/stripe-go/v74/webhook"
)

type StripeUsecase struct {
    webhookSecret string
}

func NewStripeUsecase() *StripeUsecase {
    stripe.Key = os.Getenv("STRIPE_SECRET_KEY")
    return &StripeUsecase{
        webhookSecret: os.Getenv("STRIPE_WEBHOOK_SECRET"),
    }
}

func (s *StripeUsecase) CreatePaymentIntent(amount int64, currency, customerID string) (*stripe.PaymentIntent, error) {
    params := &stripe.PaymentIntentParams{
        Amount:   stripe.Int64(amount),
        Currency: stripe.String(currency),
        Customer: stripe.String(customerID),
        Metadata: map[string]string{
            "integration": "pcc-lms",
        },
    }

    return paymentintent.New(params)
}
```

### **Semana 9-10: Frontend Integration**

#### Objetivos

- [x] React frontend con Vite
- [x] Integración con APIs Go
- [x] Video player seguro
- [x] Dashboard responsive

#### Frontend Stack

```typescript
// frontend/src/services/api.ts
import axios from 'axios';

const API_BASE_URL = process.env.VITE_API_URL || 'http://localhost:8080/api/v1';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
});

// Interceptor para auth token
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Video streaming con token seguro
export const generateStreamToken = async (videoId: string) => {
  const response = await apiClient.post('/video/generate-token', { videoId });
  return response.data;
};

export const getSecureVideoUrl = async (videoId: string) => {
  const { token } = await generateStreamToken(videoId);
  return `${API_BASE_URL}/video/stream/${videoId}?token=${token}`;
};
```

### **Semana 11-12: Production & DevOps**

#### Objetivos

- [x] Docker containerization
- [x] CI/CD pipeline
- [x] Monitoring & Logging
- [x] Performance optimization

#### Production Setup

```dockerfile
# Dockerfile.production
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main cmd/server/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/main .
COPY --from=builder /app/migrations ./migrations

EXPOSE 8080
CMD ["./main"]
```

```yaml
# docker-compose.production.yml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.production
    ports:
      - '8080:8080'
    environment:
      - DB_HOST=postgres
      - REDIS_URL=redis:6379
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: pcc_lms
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

  nginx:
    image: nginx:alpine
    ports:
      - '80:80'
      - '443:443'
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/ssl
    depends_on:
      - app

volumes:
  postgres_data:
  redis_data:
```

---

## 🛠️ Tech Stack Detallado

### **Backend (Go)**

```yaml
framework: 'Gin Gonic (HTTP router)'
database: 'PostgreSQL + GORM'
cache: 'Redis'
auth: 'JWT + refresh tokens'
payments: 'Stripe API'
storage: 'AWS S3 / Local filesystem'
websockets: 'Gorilla WebSocket'
testing: 'Testify + Ginkgo'
```

### **Frontend (React)**

```yaml
framework: 'React 18 + TypeScript'
build: 'Vite'
ui: 'Tailwind CSS + HeadlessUI'
state: 'Zustand'
forms: 'React Hook Form + Zod'
requests: 'Axios'
video: 'Video.js + HLS.js'
```

### **Infrastructure**

```yaml
containerization: 'Docker + Docker Compose'
reverse_proxy: 'Nginx'
ssl: "Let's Encrypt"
monitoring: 'Prometheus + Grafana'
logging: 'ELK Stack'
deployment: 'GitHub Actions'
```

---

## 📊 Cronograma Detallado

### **Semanas 1-2: Foundation** (16 días)

```yaml
días_1_3:
  - Setup Go workspace
  - Database schema y migrations
  - Auth service básico

días_4_8:
  - User management completo
  - JWT implementation
  - Basic middleware (CORS, security headers)

días_9_12:
  - Testing setup
  - Docker development environment
  - CI básico

días_13_16:
  - Documentación API
  - Code review y refactor
  - Performance baseline
```

### **Semanas 3-4: Core Business** (16 días)

```yaml
días_17_20:
  - Course management service
  - Content management service

días_21_24:
  - Enrollment system
  - Progress tracking

días_25_28:
  - Search functionality
  - Filtering y pagination

días_29_32:
  - Integration testing
  - API documentation
```

### **Semanas 5-6: Video Protection** ⭐ (16 días)

```yaml
días_33_36:
  - Video upload y processing
  - Encryption implementation

días_37_40:
  - Streaming token system
  - Rate limiting avanzado

días_41_44:
  - Watermarking dinámico
  - Device fingerprinting

días_45_48:
  - Security monitoring
  - Anti-piracy measures
```

### **Semanas 7-8: Advanced Features** (16 días)

```yaml
días_49_52:
  - Payment integration (Stripe)
  - Webhook handling

días_53_56:
  - Assignment system
  - Grading functionality

días_57_60:
  - Real-time notifications
  - WebSocket implementation

días_61_64:
  - Analytics básicos
  - Reporting dashboard
```

### **Semanas 9-10: Frontend** (16 días)

```yaml
días_65_68:
  - React setup y routing
  - Authentication flow

días_69_72:
  - Course catalog
  - Video player integration

días_73_76:
  - User dashboard
  - Payment flow

días_77_80:
  - Mobile responsiveness
  - Performance optimization
```

### **Semanas 11-12: Production** (16 días)

```yaml
días_81_84:
  - Production Docker setup
  - CI/CD pipeline

días_85_88:
  - Monitoring y logging
  - Performance tuning

días_89_92:
  - Security audit
  - Load testing

días_93_96:
  - Documentation final
  - Deployment y go-live
```

---

## 🎯 Milestones Críticos

### **Week 2 Checkpoint**

- ✅ Authentication funcional
- ✅ Database setup completo
- ✅ Docker development environment
- ✅ Basic API endpoints

### **Week 4 Checkpoint**

- ✅ Core business logic completo
- ✅ Course management funcional
- ✅ Enrollment system working
- ✅ Progress tracking implementado

### **Week 6 Checkpoint** ⭐

- ✅ Video protection implementado
- ✅ Security measures completas
- ✅ Token system funcional
- ✅ Anti-piracy measures activas

### **Week 8 Checkpoint**

- ✅ Payment integration completa
- ✅ Advanced features implementadas
- ✅ Real-time features working
- ✅ Analytics básicos funcionando

### **Week 10 Checkpoint**

- ✅ Frontend completamente integrado
- ✅ User experience pulida
- ✅ Mobile-responsive
- ✅ Performance optimizada

### **Week 12 Final**

- ✅ Production-ready deployment
- ✅ Monitoring y logging completo
- ✅ Security audit pasado
- ✅ Documentation completa

---

## 💰 Budget Breakdown (Solopreneur)

### **Fase 1: Development (Semanas 1-8)**

```yaml
infrastructure:
  - VPS desarrollo: $20/mes
  - Domain: $15/año
  - SSL: $0 (Let's Encrypt)

tools:
  - GitHub Pro: $0 (público)
  - Stripe testing: $0
  - PostgreSQL: $0 (self-hosted)

total_fase_1: ~$40/mes
```

### **Fase 2: Testing (Semanas 9-10)**

```yaml
infrastructure:
  - VPS staging: $40/mes
  - CDN básico: $10/mes
  - Monitoring: $0 (self-hosted)

total_fase_2: ~$90/mes
```

### **Fase 3: Production (Semanas 11-12)**

```yaml
infrastructure:
  - VPS production: $80/mes
  - CDN profesional: $30/mes
  - Backup storage: $10/mes
  - SSL certificate: $0

services:
  - Stripe: 2.9% + $0.30 por transacción
  - Email service: $20/mes

total_fase_3: ~$140/mes + fees
```

---

## 🚀 Go Packages Esenciales

### **Core Dependencies**

```go
// go.mod
module github.com/pcc-lms/backend

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/golang-jwt/jwt/v5 v5.0.0
    github.com/google/uuid v1.3.0
    gorm.io/gorm v1.25.0
    gorm.io/driver/postgres v1.5.0
    github.com/redis/go-redis/v9 v9.0.5
    github.com/stripe/stripe-go/v74 v74.0.0
    github.com/gorilla/websocket v1.5.0
    golang.org/x/crypto v0.10.0
    github.com/aws/aws-sdk-go v1.44.0
)

require (
    github.com/stretchr/testify v1.8.4 // testing
    github.com/onsi/ginkgo/v2 v2.11.0 // BDD testing
    github.com/onsi/gomega v1.27.8 // matchers
    github.com/golang-migrate/migrate/v4 v4.16.0 // migrations
    github.com/spf13/viper v1.16.0 // configuration
    github.com/rs/zerolog v1.29.1 // structured logging
)
```

### **Performance Packages**

```go
require (
    github.com/valyala/fasthttp v1.48.0 // si necesitas ultra performance
    github.com/bytedance/sonic v1.9.1 // JSON ultra-rápido
    github.com/klauspost/compress v1.16.7 // compression
    github.com/allegro/bigcache/v3 v3.1.0 // in-memory cache
)
```

---

## 📈 Performance Targets

### **Response Time Goals**

```yaml
authentication: '< 50ms'
course_listing: '< 100ms'
video_token_generation: '< 30ms'
video_streaming_start: '< 200ms'
payment_processing: '< 500ms'
```

### **Scalability Goals**

```yaml
concurrent_users: '1000+ usuarios simultáneos'
video_streams: '100+ streams concurrentes'
database_queries: '< 10ms promedio'
memory_usage: '< 512MB por instancia'
cpu_usage: '< 70% bajo carga normal'
```

### **Security Goals**

```yaml
jwt_validation: '< 5ms'
rate_limiting: '< 1ms overhead'
encryption_overhead: '< 10ms por segmento'
token_generation: '< 20ms'
```

---

## 🎯 Próximos Pasos Inmediatos

### **Esta Semana**

1. **Setup inicial Go workspace** (1 día)
2. **Database schema y migrations** (1 día)
3. **Authentication service básico** (2 días)
4. **Docker development setup** (1 día)

### **Comandos Para Empezar**

```bash
# 1. Crear estructura del proyecto
mkdir -p be/go/{cmd/server,internal/{auth,user,course,video,payment}/domain,pkg/{database,middleware,security}}
cd be/go

# 2. Inicializar Go module
go mod init github.com/pcc-lms/backend

# 3. Instalar dependencias core
go get github.com/gin-gonic/gin
go get github.com/golang-jwt/jwt/v5
go get gorm.io/gorm gorm.io/driver/postgres
go get github.com/google/uuid

# 4. Crear database
createdb pcc_lms_dev

# 5. Setup Docker para desarrollo
docker-compose -f docker-compose.dev.yml up -d
```

¿Quieres que profundice en alguna semana específica o necesitas el código detallado para empezar con el setup inicial?
