# 🎓 PCC LMS — Programar Con Criterio

**LMS Open Source Multi-Stack con IA y Business Intelligence**

[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Go](https://img.shields.io/badge/Go-00ADD8?style=flat&logo=go&logoColor=white)](https://golang.org/)
[![Express](https://img.shields.io/badge/Express-000000?style=flat&logo=express&logoColor=white)](https://expressjs.com/)
[![Next.js](https://img.shields.io/badge/Next.js-000000?style=flat&logo=next.js&logoColor=white)](https://nextjs.org/)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-6DB33F?style=flat&logo=spring&logoColor=white)](https://spring.io/projects/spring-boot)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Contributors](https://img.shields.io/github/contributors/yourusername/pcc-lms)](https://github.com/yourusername/pcc-lms/graphs/contributors)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

---

## 🎯 Visión

LMS moderno con microservicios multi-stack, IA integrada y Business Intelligence para crear experiencias de aprendizaje personalizadas y datos accionables para instructores y dueños de plataforma.

## 🏗️ Arquitectura

- **Frontend único:** React 19 + Vite + Tailwind CSS
- **Backend:** Microservicios multi-stack (FastAPI, Golang, Express, Spring Boot)
- **IA y BI:** Servicios de primer nivel para personalización y analytics
- **HATEOAS:** APIs hipermedia para navegación dinámica y descubrimiento
- **Traefik:** API Gateway con service discovery y load balancing automático
- **Infraestructura:** Docker + Kubernetes + PostgreSQL + Redis + observabilidad completa

## 📋 Estado del Proyecto

✅ **Documentación completa** en `/_docs/` (estructura categorizada)

- **Architecture:** Diseño técnico, base de datos, infraestructura
- **Business:** Requisitos funcionales/no funcionales, user stories
- **Development:** Estándares de desarrollo y herramientas
- **Operations:** Métricas, monorepo strategy, separación
- **Security:** Políticas de ciberseguridad (LOCAL ONLY)

🚧 **Próximos pasos:**

- Implementación de microservicios según backlog
- Setup de infraestructura con Traefik
- APIs HATEOAS para descubrimiento dinámico
- Frontend React con componentes base

## 🔧 Guía rápida

### Documentación

```bash
# Revisar documentación por categorías
ls _docs/                     # Ver todas las categorías

# Architecture
cat _docs/architecture/database-architecture.md
cat _docs/architecture/infrastructure-traefik.md

# Business Requirements
cat _docs/business/functional-requirements.md
cat _docs/business/non-functional-requirements.md

# Development
cat _docs/development/development-standards.md
```

### Convenciones

- **Nomenclatura técnica:** Inglés únicamente
- **Documentación:** Español
- **Arquitectura:** Clean Architecture por microservicio
- **APIs:** REST `/api/v1/` con JSON camelCase
- **BD:** PostgreSQL snake_case

## 📁 Estructura

```text
├── _docs/                    # Documentación categorizada
│   ├── architecture/         # Diseño técnico, DB, infraestructura
│   ├── business/             # Requisitos, user stories
│   ├── development/          # Estándares de desarrollo
│   ├── operations/           # Métricas, monorepo strategy
│   └── security/             # Ciberseguridad (LOCAL ONLY)
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

## 🛡️ Seguridad

PCC LMS implementa **seguridad multicapa** para deployment en producción:

- 🔐 **Autenticación JWT** con rotación automática
- 🛡️ **Rate limiting** y protección DDoS
- 🔒 **SSL/TLS obligatorio** con Let's Encrypt
- 🚨 **Monitoreo 24/7** con Fail2Ban
- 📋 **Políticas completas** en [SECURITY.md](SECURITY.md)

Para reportar vulnerabilidades: [security@pcc-lms.com](mailto:security@pcc-lms.com)

## 📚 Documentación Técnica

Ver [`_docs/README.md`](_docs/README.md) para navegación completa por categorías:

- 🏗️ **Architecture:** [`database-architecture.md`](_docs/architecture/database-architecture.md), [`infrastructure-traefik.md`](_docs/architecture/infrastructure-traefik.md)
- � **Business:** [`functional-requirements.md`](_docs/business/functional-requirements.md), [`user-stories.md`](_docs/business/user-stories.md)
- � **Development:** [`development-standards.md`](_docs/development/development-standards.md)
- ⚙️ **Operations:** [`monorepo-separation-scorecard.md`](_docs/operations/monorepo-separation-scorecard.md)

> 🔐 **Nota:** Documentación de seguridad no se sincroniza con GitHub (solo local)

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Lee nuestra [Guía de Contribución](CONTRIBUTING.md) para empezar.

**Estándares obligatorios:**

- ✅ **PNPM** para gestión de dependencias (no NPM/Yarn)
- ✅ **Clean Architecture** en todos los servicios
- ✅ **Tests** con cobertura >80%
- ✅ **Seguridad** verificada antes de merge

---

**Consultar `.vscode/copilot-instructions.md` para convenciones técnicas detalladas**
