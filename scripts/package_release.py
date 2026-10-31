import os
import shutil
import zipfile

BASE_DIR = r"d:\PROJECTS\WEBSITES\DK Enterprises"
FRONTEND_DIST = os.path.join(BASE_DIR, "frontend", "dist")
BACKEND_DIR = os.path.join(BASE_DIR, "backend")
RELEASE_DIR = os.path.join(BASE_DIR, "release")
PKG_DIR = os.path.join(RELEASE_DIR, "dk_track_production_package")

os.makedirs(PKG_DIR, exist_ok=True)
os.makedirs(os.path.join(PKG_DIR, "public_html"), exist_ok=True)
os.makedirs(os.path.join(PKG_DIR, "dk-track-backend"), exist_ok=True)

# 1. Copy Frontend Static Bundle to public_html
print("Copying compiled frontend to public_html...")
for item in os.listdir(FRONTEND_DIST):
    s = os.path.join(FRONTEND_DIST, item)
    d = os.path.join(PKG_DIR, "public_html", item)
    if os.path.isdir(s):
        if os.path.exists(d):
            shutil.rmtree(d)
        shutil.copytree(s, d)
    else:
        shutil.copy2(s, d)

# 2. Copy Backend to dk-track-backend (placed one level above public_html for security)
print("Copying PHP 8.2+ Backend API...")
for folder in ["config", "src", "public"]:
    s = os.path.join(BACKEND_DIR, folder)
    d = os.path.join(PKG_DIR, "dk-track-backend", folder)
    if os.path.exists(d):
        shutil.rmtree(d)
    shutil.copytree(s, d)

# Also copy public/index.php & .htaccess to public_html/api/v1/ for simple shared hosting setups
api_dir = os.path.join(PKG_DIR, "public_html", "api", "v1")
os.makedirs(api_dir, exist_ok=True)
shutil.copy2(os.path.join(BACKEND_DIR, "public", "index.php"), os.path.join(api_dir, "index.php"))
shutil.copy2(os.path.join(BACKEND_DIR, "public", ".htaccess"), os.path.join(api_dir, ".htaccess"))

# Also copy src and config into public_html/api/ so it's fully self-contained on simple shared hosting
shutil.copytree(os.path.join(BACKEND_DIR, "src"), os.path.join(PKG_DIR, "public_html", "api", "src"), dirs_exist_ok=True)
shutil.copytree(os.path.join(BACKEND_DIR, "config"), os.path.join(PKG_DIR, "public_html", "api", "config"), dirs_exist_ok=True)

# Create universal front controller index.php for Laravel Herd and cPanel fallback
herd_front_controller = """<?php
// DK Track — Herd / Valet / Shared Hosting Universal Front Controller
$uri = urldecode(parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH));

// 1. Route API requests to REST front controller
if (str_starts_with($uri, '/api/')) {
    require_once __DIR__ . '/api/v1/index.php';
    exit;
}

// 2. Direct static files for Herd PHP server
$filePath = __DIR__ . $uri;
if ($uri !== '/' && file_exists($filePath) && !is_dir($filePath)) {
    return false;
}

// 3. Deliver SPA frontend
if (file_exists(__DIR__ . '/index.html')) {
    readfile(__DIR__ . '/index.html');
} else {
    echo "DK Track Front Controller Running.";
}
exit;
"""
with open(os.path.join(PKG_DIR, "public_html", "index.php"), "w", encoding="utf-8") as f:
    f.write(herd_front_controller)

# 3. Compile Master Database Setup SQL (Schema + Ground Seeds)
print("Compiling Master Database SQL...")
schema_file = os.path.join(BACKEND_DIR, "database", "schema.sql")
seeds_file = os.path.join(BACKEND_DIR, "database", "seeds.sql")
master_sql = os.path.join(RELEASE_DIR, "dk_enterprises_master_database_setup.sql")

with open(master_sql, "w", encoding="utf-8") as out_f:
    out_f.write("-- ======================================================================\n")
    out_f.write("-- DK TRACK — MASTER PRODUCTION DATABASE SETUP (MySQL 8.0 / InnoDB)\n")
    out_f.write("-- Tailored for DK Enterprises: Tankers, Water Cans & Bakery\n")
    out_f.write("-- ======================================================================\n\n")
    with open(schema_file, "r", encoding="utf-8") as sf:
        out_f.write(sf.read())
    out_f.write("\n\n-- ======================================================================\n")
    out_f.write("-- PRODUCTION SEED DATA (FROM CLIENT NOTEBOOKS & GROUND RECORDS)\n")
    out_f.write("-- ======================================================================\n\n")
    with open(seeds_file, "r", encoding="utf-8") as sef:
        out_f.write(sef.read())

shutil.copy2(master_sql, os.path.join(PKG_DIR, "database_setup.sql"))

# 4. Create ZIP archive for 1-Click Upload to Hostinger File Manager
zip_path = os.path.join(RELEASE_DIR, "dk_track_hostinger_cpanel_production.zip")
print(f"Creating production zip at {zip_path}...")
with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for root, dirs, files in os.walk(PKG_DIR):
        for file in files:
            file_path = os.path.join(root, file)
            arcname = os.path.relpath(file_path, PKG_DIR)
            zipf.write(file_path, arcname)

print("SUCCESS: Production release package created successfully!")
print(f"Zip file size: {os.path.getsize(zip_path) / 1024:.1f} KB")
