# Estándares de Desarrollo - PCC LMS

**Versión:** 2025-08-08  
**Aplicable a:** Todos los stacks del proyecto

---

## 📦 Gestión de Dependencias

### PNPM como Estándar Obligatorio

**Decisión:** PCC LMS utiliza **PNPM** exclusivamente para todos los proyectos Node.js/JavaScript.

#### ✅ **Por qué PNPM sobre NPM**

##### 1. **Seguridad Superior**

- **Aislamiento estricto**: Previene dependency confusion attacks
- **Verificación de integridad**: SHA + content verification
- **Auditoría robusta**: Detecta más vulnerabilidades que npm audit

##### 2. **Eficiencia**

- **70% menos espacio en disco**: Hard links + store global
- **2x más rápido**: Instalación y resolución de dependencias
- **Determinismo**: pnpm-lock.yaml más confiable que package-lock.json

##### 3. **Arquitectura Monorepo-Friendly**

- **Workspace nativo**: Perfecto para nuestros 78 microservicios
- **Hoisting controlado**: Evita conflictos entre servicios
- **Shared dependencies**: Optimización de almacenamiento

#### 📋 **Comandos Obligatorios**

```bash
# ✅ USAR SIEMPRE
pnpm install                    # Instalar dependencias
pnpm install --frozen-lockfile  # En CI/CD
pnpm add <package>             # Agregar dependencia
pnpm remove <package>          # Remover dependencia
pnpm update                    # Actualizar dependencias
pnpm audit                     # Auditoría de seguridad
pnpm run <script>              # Ejecutar scripts

# ❌ PROHIBIDO
npm install    # Usar pnpm install
npm ci         # Usar pnpm install --frozen-lockfile
npm run        # Usar pnpm run
yarn install   # Solo PNPM permitido
```

#### ⚙️ **Configuración Estándar**

##### .pnpmrc (root del proyecto)

```ini
# Configuración global PNPM
strict-peer-dependencies=true
auto-install-peers=false
enable-pre-post-scripts=false
registry=https://registry.npmjs.org/
verify-store-integrity=true
side-effects-cache=false
frozen-lockfile=true
```

##### package.json engines

```json
{
  "engines": {
    "node": ">=22.18.0",
    "pnpm": ">=8.0.0"
  },
  "packageManager": "pnpm@8.0.0"
}
```

---

## 🏗️ Stack-Specific Standards

### Frontend (React + Vite)

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "lint:fix": "pnpm lint --fix"
  }
}
```

### Express/Node.js Services

```json
{
  "scripts": {
    "start": "node dist/index.js",
    "dev": "nodemon src/index.ts",
    "build": "tsc",
    "test": "jest",
    "lint": "eslint src --ext .ts"
  }
}
```

### Next.js Services

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  }
}
```

---

## 🚀 CI/CD Integration

### GitHub Actions Workflow

```yaml
name: Dependencies & Security

jobs:
  dependencies:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22.18'

      - name: Setup PNPM
        uses: pnpm/action-setup@v2
        with:
          version: 8

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Security audit
        run: pnpm audit --audit-level moderate

      - name: Check outdated
        run: pnpm outdated --format table
```

### Docker Integration

```dockerfile
# Dockerfile template para servicios Node.js
FROM node:22.18-alpine

# Install PNPM globally
RUN npm install -g pnpm@8

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies with frozen lockfile
RUN pnpm install --frozen-lockfile --production

# Copy source code
COPY . .

# Build if needed
RUN pnpm run build

# Start application
CMD ["pnpm", "start"]
```

---

## 📁 Workspace Configuration

### Root pnpm-workspace.yaml

```yaml
packages:
  # Frontend
  - 'fe'
  # Backend services by stack
  - 'be/express/*'
  - 'be/nextjs/*'
  # Shared packages
  - 'packages/*'
```

### Shared Dependencies

```json
// Root package.json
{
  "devDependencies": {
    "@types/node": "^22.18.0",
    "eslint": "^8.0.0",
    "prettier": "^3.0.0",
    "typescript": "^5.0.0"
  }
}
```

---

## 🔒 Security Policies

### Dependency Management

- **Audit frequency**: Semanal obligatorio
- **Update strategy**: Patch automático, minor/major manual
- **Vulnerability response**: <24h para critical, <7d para high

### Allowed Registries

```ini
# Solo registry oficial
registry=https://registry.npmjs.org/

# Prohibidos registries alternativos sin aprobación
# registry=https://npm.pkg.github.com/ # Requiere aprobación
```

---

## 📊 Monitoring & Metrics

### Bundle Analysis

```json
{
  "scripts": {
    "analyze": "pnpm build && npx bundle-analyzer dist",
    "size-check": "size-limit"
  }
}
```

### Performance Tracking

- **Bundle size**: <500KB gzipped para frontend
- **Dependencies**: <50 en production
- **Install time**: <2min en CI/CD

---

## 🎯 Enforcement

### Pre-commit Hooks

```json
// .husky/pre-commit
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

pnpm audit --audit-level high
pnpm run lint
pnpm run type-check
```

### Package.json Validation

```bash
# Verificar que se usa PNPM
if [ -f "package-lock.json" ] || [ -f "yarn.lock" ]; then
  echo "❌ Solo pnpm-lock.yaml permitido"
  exit 1
fi
```

---

## 🔧 Justificación Técnica de Versiones

#### Node.js 22.18 LTS vs Versiones Anteriores

**¿Por qué Node.js 22.18 LTS y no 18.x?**

| Característica     | Node.js 18.x               | Node.js 22.18 LTS     | Impacto               |
| ------------------ | -------------------------- | --------------------- | --------------------- |
| **Performance**    | Baseline                   | +15% mejor V8         | 🚀 Mayor throughput   |
| **Seguridad**      | Vulnerabilidades conocidas | Patches más recientes | 🔒 Menos CVEs         |
| **ECMAScript**     | ES2022                     | ES2024                | ✨ Nuevas features    |
| **Memory Usage**   | Baseline                   | -8% uso de memoria    | 💾 Mejor eficiencia   |
| **HTTP/3 Support** | Experimental               | Estable               | 🌐 Mejor networking   |
| **Test Runner**    | Básico                     | Mejorado              | 🧪 Testing nativo     |
| **Fetch API**      | Experimental               | Estable nativo        | 📡 Menos dependencias |

#### Ventajas Específicas para PCC LMS

```javascript
// Node.js 22.18 - Features nativas que usaremos
// 1. Test Runner nativo (menos dependencias)
import { test, describe } from 'node:test';
import assert from 'node:assert';

// 2. Fetch API nativo (sin node-fetch)
const response = await fetch('https://api.example.com');

// 3. Better ESM support
import { readFile } from 'node:fs/promises';

// 4. Enhanced error causes
throw new Error('Database error', {
  cause: originalError,
});
```

#### Beneficios de Seguridad

- **CVE Fixes**: Todas las vulnerabilidades de 18.x patcheadas
- **Modern TLS**: TLS 1.3 optimizado
- **Security Headers**: Better defaults en HTTP responses
- **Crypto Updates**: OpenSSL 3.0+ con algoritmos modernos

#### Consideraciones de Deployment

- **Hostinger VPS**: Compatible con Node.js 22.x
- **Docker Images**: `node:22.18-alpine` disponible y optimizada
- **Memory Footprint**: -8% menos uso de RAM vs 18.x
- **Cold Start**: 12% más rápido en contenedores

```

```
