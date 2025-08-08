# PCC LMS — Programar Con Criterio

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Contributors](https://img.shields.io/github/contributors/yourusername/pcc-lms)](https://github.com/yourusername/pcc-lms/graphs/contributors)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![Code of Conduct](https://img.shields.io/badge/Code%20of%20Conduct-v1.0-ff69b4.svg)](CODE_OF_CONDUCT.md)

> 🎓 **LMS open source moderno** con arquitectura de microservicios multi-stack, IA integrada y Business Intelligence para crear experiencias de aprendizaje personalizadas.

## 🌟 Características

- 🚀 **Multi-stack**: FastAPI, Go, Express, Next.js, Spring Boot (Java/Kotlin)
- 🤖 **IA Integrada**: Personalización de contenido y recomendaciones inteligentes
- 📊 **Business Intelligence**: Analytics avanzado y dashboards en tiempo real
- 🏗️ **Clean Architecture**: Código limpio, mantenible y testeable
- 🐳 **Cloud Native**: Docker, Kubernetes, microservicios escalables
- 🔒 **Seguridad**: JWT, OAuth2, encriptación end-to-end
- 📱 **Responsive**: UI moderna con React 19 + Tailwind CSS

## 🏗️ Arquitectura

### Backend Multi-Stack

```text
be/
├── fastapi/     # Python - IA y Analytics
├── go/          # Go - Performance crítico
├── express/     # Node.js - APIs rápidas
├── nextjs/      # Full-stack - SSR/API routes
├── sb-java/     # Spring Boot Java - Enterprise
└── sb-kotlin/   # Spring Boot Kotlin - Moderno
```

### Base de Datos Unificada

```text
db/
├── migrations/  # PostgreSQL, MongoDB, ClickHouse
├── seeds/       # Datos iniciales
├── schemas/     # Documentación de esquemas
└── scripts/     # Herramientas de gestión
```

### Servicios Principales

- **auth-service**: Autenticación y autorización
- **users-service**: Gestión de usuarios y perfiles
- **courses-service**: Cursos y contenido educativo
- **ai-service**: IA y machine learning
- **analytics-service**: Métricas y reportes
- **business-intelligence-service**: BI y dashboards

## 🚀 Inicio Rápido

### Prerrequisitos

- Docker & Docker Compose
- Node.js 18+ (para frontend)
- Python 3.11+ (para FastAPI)
- Go 1.21+ (para servicios Go)
- Java 17+ (para Spring Boot)

### Instalación

1. **Clonar el repositorio**

```bash
git clone https://github.com/yourusername/pcc-lms.git
cd pcc-lms
```

2. **Configurar base de datos**

```bash
cd db
cp .env.example .env
# Editar .env con tus configuraciones
chmod +x scripts/db-manager.sh
./scripts/db-manager.sh setup
```

3. **Iniciar servicios**

```bash
# Backend (elige tu stack preferido)
cd be/fastapi && docker-compose up -d
# o
cd be/go && docker-compose up -d

# Frontend
cd fe && npm install && npm run dev
```

4. **Verificar instalación**

```bash
curl http://localhost:3000/health
```

## 📚 Documentación

- 📋 [Requisitos Funcionales](_docs/functional-requirements.md)
- ⚡ [Requisitos No Funcionales](_docs/non-functional-requirements.md)
- 📖 [Historias de Usuario](_docs/user-stories.md)
- 🗄️ [Arquitectura de Base de Datos](_docs/database-architecture.md)
- 🤝 [Guía de Contribución](CONTRIBUTING.md)

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Lee nuestra [Guía de Contribución](CONTRIBUTING.md) para empezar.

1. Fork el proyecto
2. Crea tu rama feature (`git checkout -b feature/amazing-feature`)
3. Commit tus cambios (`git commit -m 'Add amazing feature'`)
4. Push a la rama (`git push origin feature/amazing-feature`)
5. Abre un Pull Request

## 🛡️ Seguridad

Para reportar vulnerabilidades de seguridad, consulta [SECURITY.md](SECURITY.md).

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver [LICENSE](LICENSE) para más detalles.

## 🙏 Reconocimientos

- Comunidad open source
- Contribuidores y mantenedores
- [Lista completa de contribuidores](CONTRIBUTORS.md)

## 📞 Soporte

- 🐛 [Reportar Bug](https://github.com/yourusername/pcc-lms/issues)
- 💡 [Solicitar Feature](https://github.com/yourusername/pcc-lms/issues)
- 💬 [Discusiones](https://github.com/yourusername/pcc-lms/discussions)

---

**Hecho con ❤️ por la comunidad Programar Con Criterio**

## 📁 Estructura

```text
├── _docs/                    # Documentación central
├── frontend/                 # React app (por implementar)
├── services/                 # Microservicios (por implementar)
├── infra/                    # Docker, Nginx, K8s (por implementar)
└── scripts/                  # Scripts dev/prod (por implementar)
```

## 🤖 IA y BI como primer nivel

- **ai-service:** RAG, chatbot, recomendaciones, embeddings semánticos
- **business-intelligence-service:** Dashboards ejecutivos, cohortes, forecasting

## 🎯 MVP (8-10 semanas)

1. Autenticación y gestión de usuarios
2. Catálogo de cursos y matriculación
3. Contenido multimedia y progreso
4. Evaluaciones y calificaciones
5. Pagos integrados (Stripe/MercadoPago)
6. Panel de instructor y estudiante
7. IA para recomendaciones básicas
8. BI para métricas de negocio

---

**Consultar `.vscode/copilot-instructions.md` para convenciones técnicas detalladas**
