# PCC LMS - Assets

Esta carpeta contiene todos los recursos visuales y de marca del proyecto PCC LMS.

## 📁 Estructura

```
assets/
├── branding/           # Guías de marca y especificaciones
├── banners/           # Banners para README y documentación
├── logos/             # Logos y variaciones
└── icons/             # Iconografía del sistema (futuro)
```

## 🎨 Paleta de Colores

| Color              | Hex       | Uso                         |
| ------------------ | --------- | --------------------------- |
| **Verde PCC**      | `#23a500` | Principal, CTA, Success     |
| **Naranja Accent** | `#ff7e05` | Accent, Warning, Highlights |
| **Gris Medio**     | `#585858` | Texto secundario, Borders   |
| **Negro**          | `#000000` | Texto principal, Headers    |
| **Blanco**         | `#ffffff` | Backgrounds, Contrast       |

## 🖼️ Recursos Disponibles

### Banners

- `banners/main-banner.svg` - Banner principal (1200x300px)
- `banners/github-banner.svg` - Banner compacto para GitHub (800x200px)

### Logos

- `logos/pcc-logo.svg` - Logo principal (200x200px)

### Branding

- `branding/brand-guidelines.md` - Guía completa de marca

## 🔧 Uso

### En README.md

```markdown
![PCC LMS Banner](assets/banners/github-banner.svg)
```

### En documentación

```markdown
![PCC LMS](assets/logos/pcc-logo.svg)
```

### En código CSS

```css
:root {
  --color-primary: #23a500;
  --color-accent: #ff7e05;
  --color-neutral: #585858;
  --color-text: #000000;
  --color-background: #ffffff;
}
```

## 📐 Especificaciones

### Dimensiones Recomendadas

- **Banner GitHub**: 800x200px (ratio 4:1)
- **Banner principal**: 1200x300px (ratio 4:1)
- **Logo**: 200x200px (cuadrado)
- **Favicon**: 32x32px, 64x64px

### Formatos

- **SVG**: Preferido para escalabilidad
- **PNG**: Para compatibilidad
- **WebP**: Para web optimizada

## 🎯 Directrices de Uso

### ✅ Permitido

- Usar los colores exactos especificados
- Mantener proporciones del logo
- Aplicar en fondos apropiados
- Usar en materiales oficiales del proyecto

### ❌ No Permitido

- Modificar los colores de marca
- Distorsionar las proporciones
- Usar sobre fondos que reduzcan legibilidad
- Aplicar efectos no autorizados

## 📄 Licencia

Los assets de marca están sujetos a la misma licencia MIT del proyecto, pero se solicita uso responsable de la identidad visual.

## 🤝 Contribuciones

Para proponer cambios o nuevos assets:

1. Seguir las guías de marca existentes
2. Mantener consistencia visual
3. Proporcionar múltiples formatos
4. Documentar el uso propuesto

---

**Última actualización**: 2025-08-08
