# Documentación del Proyecto PCC LMS

Esta carpeta contiene toda la documentación técnica y de negocio del proyecto, organizada por categorías.

## 📁 Estructura Organizacional

```
_docs/
├── architecture/           # Arquitectura técnica y diseño
├── business/              # Requisitos y especificaciones de negocio
├── development/           # Estándares y procesos de desarrollo
├── operations/            # Gestión de operaciones y métricas
└── security/              # Políticas de seguridad (LOCAL ONLY)
```

## 📋 Índice de Documentación

### 🏗️ Architecture

- [`database-architecture.md`](architecture/database-architecture.md) - Diseño de base de datos multi-engine
- [`infrastructure-traefik.md`](architecture/infrastructure-traefik.md) - Configuración de API Gateway
- [`uuid-security-analysis.md`](architecture/uuid-security-analysis.md) - Análisis de seguridad UUIDs

### 💼 Business

- [`functional-requirements.md`](business/functional-requirements.md) - Requisitos funcionales completos
- [`non-functional-requirements.md`](business/non-functional-requirements.md) - SLOs y métricas de calidad
- [`user-stories.md`](business/user-stories.md) - Historias de usuario y criterios
- [`info-proyecto.md`](business/info-proyecto.md) - Información general del proyecto

### 🔧 Development

- [`development-standards.md`](development/development-standards.md) - Estándares y herramientas de desarrollo

### ⚙️ Operations

- [`monorepo-separation-scorecard.md`](operations/monorepo-separation-scorecard.md) - Métricas para decisión de separación

### 🔐 Security _(Local Only)_

- `granular-permissions.md` - Políticas granulares de permisos
- `cybersecurity-policies.md` - Políticas completas de ciberseguridad

> ⚠️ **Nota de Seguridad**: Los archivos en `security/` no se sincronizan con GitHub por razones de seguridad. Se mantienen únicamente en el repositorio local.

## 📖 Guías de Navegación

### Para Desarrolladores

1. Empezar con [`development-standards.md`](development/development-standards.md)
2. Revisar arquitectura en [`database-architecture.md`](architecture/database-architecture.md)
3. Consultar requisitos no funcionales en [`non-functional-requirements.md`](business/non-functional-requirements.md)

### Para Product Managers

1. Revisar [`functional-requirements.md`](business/functional-requirements.md)
2. Consultar [`user-stories.md`](business/user-stories.md)
3. Verificar SLOs en [`non-functional-requirements.md`](business/non-functional-requirements.md)

### Para DevOps/SRE

1. Configuración de infraestructura: [`infrastructure-traefik.md`](architecture/infrastructure-traefik.md)
2. Métricas de operación: [`monorepo-separation-scorecard.md`](operations/monorepo-separation-scorecard.md)
3. Políticas de seguridad: `security/` (local only)

### Para Security Team

1. Acceso solo a archivos locales en `security/`
2. Políticas granulares de permisos
3. Procedimientos de ciberseguridad

## 🔄 Mantenimiento

### Actualizaciones

- **Frecuencia**: Según cambios en el proyecto
- **Responsable**: Tech Lead + Product Owner
- **Revisión**: Weekly standup

### Versionado

- Los documentos siguen el mismo versionado que el proyecto
- Cambios significativos requieren PR review
- Documentación de seguridad requiere aprobación del Security Team

### Acceso

- **Documentación general**: Todo el equipo
- **Documentación de seguridad**: Solo Security Team y Tech Leads
- **Documentación de negocio**: Product Team + Development Team

---

**Última actualización**: Agosto 2025  
**Mantenedores**: Tech Lead Team
