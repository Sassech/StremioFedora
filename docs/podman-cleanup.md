# Podman cleanup — comandos y notas

Este documento lista comandos útiles para limpiar espacio y cachés usados por Podman. Úsalos con precaución: muchas de estas operaciones son destructivas y no se pueden deshacer.

## Ver uso de espacio

Mostrar el uso actual de disco por imágenes, contenedores y volúmenes:

```bash
podman system df
```

## Limpiar elementos no usados (seguro revisar primero)

- Eliminar contenedores detenidos:

```bash
podman container prune
```

- Eliminar pods sin contenedores:

```bash
podman pod prune
```

- Eliminar imágenes no referenciadas (dangling). Usa `-a` para borrar todas las imágenes no referenciadas por contenedores:

```bash
podman image prune -a
```

- Eliminar volúmenes no usados:

```bash
podman volume prune
```

## Prune todo en uno (más agresivo)

El siguiente comando elimina todo lo no usado e incluye volúmenes (usa `-f` para no pedir confirmación):

```bash
podman system prune -a --volumes -f
```

Si prefieres confirmación interactiva, omite `-f`.

## Eliminar todas las imágenes (muy destructivo)

```bash
podman rmi -a
```

## Limpiar almacenamiento local manualmente (rootless)

Si necesitas forzar una limpieza manual de caches y almacenamiento del usuario rootless:

```bash
rm -rf ~/.cache/containers ~/.local/share/containers/storage
```

Para instalaciones rootful (sistema) las rutas típicas son:

```bash
# sudo rm -rf /var/lib/containers/storage /var/cache/containers
```

## Evitar usar cache en builds

- Reconstruir sin cache (si tu versión lo soporta):

```bash
podman build --no-cache -t myimage:latest .
```

- Otra opción para builds layerless (evita capas cacheadas):

```bash
podman build --layers=false -t myimage:latest .
```

## Precauciones

- Revisa siempre qué vas a borrar antes de ejecutar. Muchas operaciones son destructivas.
- Para ver qué imágenes/contenedores/volúmenes existen antes de borrarlos, usa `podman ps -a`, `podman images` y `podman volume ls`.
- En entornos rootless los archivos creados por el demonio rootful (o por otro usuario) pueden requerir `sudo` para borrar.
- Si tienes dudas, realiza un backup o mueve archivos a otra ubicación antes de borrarlos.

---

Archivo creado automáticamente desde la guía de mantenimiento. Si quieres, puedo añadir ejemplos de uso más específicos o un script de limpieza interactivo.
