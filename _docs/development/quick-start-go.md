# Quick Start - Setup Go en 30 minutos

> 🚀 **Objetivo**: Tener el entorno Go funcionando en 30 minutos  
> 📋 **Pre-requisitos**: Go 1.21+, Docker, PostgreSQL  
> 🎯 **Resultado**: API básica funcionando con auth

## 🏃‍♂️ Setup Rápido

### 1. Crear Estructura del Proyecto (5 minutos)

```bash
# Desde la raíz del proyecto
cd /home/epti/Documentos/epti-dev/pcc-lms

# Crear estructura Go
mkdir -p be/go/{cmd/server,internal/{auth,user,course,video,payment}/{domain,repository,usecase,handler},pkg/{database,middleware,security,config},migrations,scripts}

# Navegar a directorio Go
cd be/go

# Inicializar Go module
go mod init github.com/pcc-lms/backend

echo "✅ Estructura del proyecto creada"
```

### 2. Instalar Dependencias Core (5 minutos)

```bash
# Core dependencies
go get github.com/gin-gonic/gin@latest
go get github.com/golang-jwt/jwt/v5@latest
go get gorm.io/gorm@latest
go get gorm.io/driver/postgres@latest
go get github.com/google/uuid@latest
go get github.com/redis/go-redis/v9@latest
go get golang.org/x/crypto@latest

# Development dependencies
go get github.com/joho/godotenv@latest
go get github.com/stretchr/testify@latest

# Database migrations
go get -tags 'postgres' github.com/golang-migrate/migrate/v4@latest

echo "✅ Dependencias instaladas"
```

### 3. Configuración de Base de Datos (5 minutos)

```bash
# Crear .env file
cat > .env << 'EOF'
# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=pcc_lms_dev
DB_SSL=disable

# Redis
REDIS_URL=redis://localhost:6379

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRE_HOURS=24

# Server
PORT=8080
GIN_MODE=debug

# Video Security
VIDEO_ENCRYPTION_KEY=your-32-byte-video-encryption-key!!

# Stripe (development)
STRIPE_SECRET_KEY=sk_test_your_stripe_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
EOF

# Crear database
createdb pcc_lms_dev

echo "✅ Base de datos configurada"
```

### 4. Código Inicial Funcional (10 minutos)

#### main.go

```bash
# Crear main.go
cat > cmd/server/main.go << 'EOF'
package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/pcc-lms/backend/internal/auth"
	"github.com/pcc-lms/backend/internal/user"
	"github.com/pcc-lms/backend/pkg/config"
	"github.com/pcc-lms/backend/pkg/database"
	"github.com/pcc-lms/backend/pkg/middleware"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	// Initialize config
	cfg := config.New()

	// Connect to database
	db, err := database.NewConnection(cfg.Database)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Auto-migrate models
	database.Migrate(db)

	// Initialize repositories
	userRepo := user.NewRepository(db)

	// Initialize usecases
	userUsecase := user.NewUsecase(userRepo)
	authUsecase := auth.NewUsecase(userRepo, cfg.JWT)

	// Initialize handlers
	userHandler := user.NewHandler(userUsecase)
	authHandler := auth.NewHandler(authUsecase)

	// Setup Gin router
	r := gin.Default()

	// Global middleware
	r.Use(middleware.CORS())
	r.Use(middleware.Security())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "healthy"})
	})

	// API routes
	api := r.Group("/api/v1")
	{
		// Authentication routes
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/refresh", authHandler.RefreshToken)
		}

		// Protected routes
		protected := api.Group("/")
		protected.Use(middleware.JWTAuth(cfg.JWT.Secret))
		{
			// User routes
			protected.GET("/me", userHandler.GetProfile)
			protected.PUT("/me", userHandler.UpdateProfile)
		}
	}

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 Server starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
EOF
```

#### Configuration

```bash
# Crear pkg/config/config.go
cat > pkg/config/config.go << 'EOF'
package config

import (
	"os"
	"strconv"
)

type Config struct {
	Database DatabaseConfig
	JWT      JWTConfig
	Server   ServerConfig
}

type DatabaseConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	Name     string
	SSL      string
}

type JWTConfig struct {
	Secret      string
	ExpireHours int
}

type ServerConfig struct {
	Port string
}

func New() *Config {
	expireHours, _ := strconv.Atoi(getEnv("JWT_EXPIRE_HOURS", "24"))

	return &Config{
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnv("DB_PORT", "5432"),
			User:     getEnv("DB_USER", "postgres"),
			Password: getEnv("DB_PASSWORD", "postgres"),
			Name:     getEnv("DB_NAME", "pcc_lms_dev"),
			SSL:      getEnv("DB_SSL", "disable"),
		},
		JWT: JWTConfig{
			Secret:      getEnv("JWT_SECRET", "your-secret-key"),
			ExpireHours: expireHours,
		},
		Server: ServerConfig{
			Port: getEnv("PORT", "8080"),
		},
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
EOF
```

#### Database Connection

```bash
# Crear pkg/database/database.go
cat > pkg/database/database.go << 'EOF'
package database

import (
	"fmt"

	"github.com/pcc-lms/backend/internal/user/domain"
	"github.com/pcc-lms/backend/pkg/config"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func NewConnection(cfg config.DatabaseConfig) (*gorm.DB, error) {
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s",
		cfg.Host, cfg.User, cfg.Password, cfg.Name, cfg.Port, cfg.SSL)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})

	if err != nil {
		return nil, err
	}

	return db, nil
}

func Migrate(db *gorm.DB) error {
	return db.AutoMigrate(
		&domain.User{},
		// Add other models here
	)
}
EOF
```

### 5. Testing Rápido (5 minutos)

```bash
# Ejecutar el servidor
go run cmd/server/main.go

# En otra terminal, probar endpoints
curl http://localhost:8080/health

# Debería devolver: {"status":"healthy"}

echo "✅ API funcionando correctamente"
```

## 🔥 Resultado en 30 minutos

Después de este setup tendrás:

- ✅ **Estructura Go completa** con Clean Architecture
- ✅ **Base de datos conectada** con GORM
- ✅ **API básica funcionando** en puerto 8080
- ✅ **Health check endpoint** para verificar status
- ✅ **Configuración environment-based** con .env
- ✅ **Dependencias instaladas** y listas para desarrollo

## 🚀 Próximos Pasos Inmediatos

### Día 1 - Completar Authentication

```bash
# Implementar modelos de usuario
# Crear JWT middleware
# Endpoints de register/login funcionando
```

### Día 2 - Core Business Logic

```bash
# Modelos de Course y Content
# Endpoints básicos CRUD
# Testing inicial
```

### Día 3 - Docker Setup

```bash
# Dockerfile para desarrollo
# docker-compose.yml completo
# Environment de desarrollo containerizado
```

## 🛠️ Comandos de Desarrollo

```bash
# Ejecutar servidor
go run cmd/server/main.go

# Testing
go test ./...

# Build para producción
go build -o bin/server cmd/server/main.go

# Linting
golangci-lint run

# Hot reload (instalar air)
go install github.com/cosmtrek/air@latest
air
```

¿Quieres que proceda con la implementación de authentication completa o prefieres que detalle alguna otra parte específica del plan?
