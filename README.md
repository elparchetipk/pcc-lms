# PCC LMS — Programar Con Criterio

## 🎯 Visión

LMS moderno con microservicios multi-stack, IA integrada y Business Intelligence para crear experiencias de aprendizaje personalizadas y datos accionables para instructores y dueños de plataforma.

## 🏗️ Arquitectura

- **Frontend único:** React 19 + Vite + Tailwind CSS
- **Backend:** Microservicios multi-stack (FastAPI, Golang, Express, Spring Boot)
- **IA y BI:** Servicios de primer nivel para personalización y analytics
- **Infraestructura:** Docker + Nginx + PostgreSQL + Redis + observabilidad completa

## 📋 Estado del Proyecto

✅ **Documentación completa** en `/_docs/`

- Requisitos funcionales (RFs) con IA/BI como primer nivel
- Requisitos no funcionales (RNFs) con SLOs y métricas
- Historias de usuario y criterios de aceptación
- Blueprint y visión técnica

🚧 **Próximos pasos:**

- Implementación de microservicios según backlog
- Setup de infraestructura base
- Frontend React con componentes base

## 🔧 Guía rápida

### Documentación

```bash
# Revisar requisitos funcionales
cat _docs/functional-requirements.md

# Revisar requisitos no funcionales
cat _docs/non-functional-requirements.md

# Revisar backlog de historias de usuario
cat _docs/user-stories.md
```

### Convenciones

- **Nomenclatura técnica:** Inglés únicamente
- **Documentación:** Español
- **Arquitectura:** Clean Architecture por microservicio
- **APIs:** REST `/api/v1/` con JSON camelCase
- **BD:** PostgreSQL snake_case

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
