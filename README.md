# FrameWork-Skynx
Framework avanzado de automatización en Bash para auditorías de seguridad, escaneo asíncrono de redes, generación criptográfica de payloads y desarrollo de plugins asistido por IA local (Ollama). Diseñado exclusivamente para laboratorios autorizados.

## 1. EXENCIÓN DE RESPONSABILIDAD LEGAL (DISCLAIMER)

EL USO DE ESTE SOFTWARE SIN LA AUTORIZACIÓN EXPLÍCITA DEL PROPIETARIO DE LOS SISTEMAS OBJETIVO ES ILEGAL Y CONSTITUYE UN DELITO.

Este framework ha sido desarrollado exclusivamente con fines académicos, formación en ciberseguridad, investigación de vectores de ataque y ejecución de pruebas de penetración dentro de infraestructuras controladas o laboratorios bajo propiedad y autorización expresa del auditor.

El autor no se hace responsable por el uso indebido, negligencia, daños materiales, pérdidas de información o consecuencias legales derivadas de la ejecución de los módulos incluidos en este repositorio. Al clonar, compilar o utilizar este software, el usuario acepta operar bajo los marcos regulatorios y legislaciones vigentes de su respectiva jurisdicción.

---
### Requisitos del Sistema
* Sistema Operativo: Distribuciones GNU/Linux basadas en Debian (Kali Linux, Parrot OS, Ubuntu, Debian) con el gestor de paquetes `apt` nativo.
* Entorno de Ejecución: Intérprete de comandos Bash (`/bin/bash`). No se garantiza la compatibilidad en entornos Zsh, Fish o Dash.
* 

## 2. CARACTERÍSTICAS TÉCNICAS

* Reconocimiento Asíncrono: Descubrimiento de hosts activos optimizado mediante subprocesos paralelos en la shell actual, mitigando el sobreconsumo de memoria RAM.
* Gestión de Plugins mediante IA: Interfaz de comunicación con Ollama (Qwen2.5-Coder) para la autogeneración y autocuración sintáctica de scripts en tiempo de ejecución.
* Arquitectura Criptográfica: Despliegue de stubs dinámicos y empaquetamiento de payloads cifrados mediante algoritmos basados en claves aleatorias generadas por el sistema.
* Reportes Consolidados: Exportación automatizada de resultados analíticos a formatos Markdown estructurado e informes HTML reactivos con desinfección de variables sensibles.

---
## 3. DESPLIEGUE E INSTALACIÓN

Para realizar el despliegue del framework de manera automatizada en su sistema operativo, ejecute secuencialmente los siguientes dos comandos en su terminal:

```bash
# Paso 1: Descargar el instalador automatizado desde el repositorio
curl -sSL https://githubusercontent.com -o /usr/local/bin/Skynx

# Paso 2: Creación de directorios locales del sistema
mkdir -p /etc/skynx /var/log/skynx /usr/local/share/skynx/plugins /usr/local/share/skynx/modules
chmod 755 /etc/skynx /var/log/skynx /usr/local/share/skynx

# Paso 3: Conceder privilegios de ejecución al binario en el sistema
chmod +x /usr/local/bin/Skynx
```

Una vez descargado, inicie la herramienta con privilegios administrativos para que el framework genere automáticamente sus directorios (`/etc/skynx`, `/var/log/skynx`) y su llave criptográfica única de configuración:

```bash
sudo Skynx --menu
```


---

## 4. CRÉDITOS E INSPIRACIONES

Este entorno consolida, automatiza e interactúa con herramientas líderes desarrolladas por la comunidad de seguridad de código abierto:
* Metasploit Framework (Aviso de Copyright © Rapid7)
* Nmap Network Mapper (Aviso de Copyright © Gordon Lyon)
* Hydra Password Cracker (Aviso de Copyright © van Hauser)
* RustScan Engine (Aviso de Copyright © RustScan Team)
* Ollama AI Platform (Aviso de Copyright © Ollama Team)
* Aircrack-ng Suite (Aviso de Copyright © Aircrack-ng Team)
* Hashcat GPU Cracker (Aviso de Copyright © Hashcat Team)
* Masscan Port Scanner (Aviso de Copyright © Robert Graham)
* 
