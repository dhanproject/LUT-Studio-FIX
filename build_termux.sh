# --- LUT STUDIO AUTOMATIC BUILDER FOR TERMUX ---
# Author: LUT Studio Team
# Version: 2.0.0 (Master v4.0.0 Update)

# Warna untuk output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}   🚀 LUT STUDIO MASTER AUTO-BUILDER   ${NC}"
echo -e "${YELLOW}        Version 4.0.0 (Stable)        ${NC}"
echo -e "${BLUE}=========================================${NC}"

# 0. Environment Check
echo -e "${BLUE}[0/6] Memeriksa Lingkungan...${NC}"
NODE_VER=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VER" -lt 20 ]; then
    echo -e "${RED}ERR: Node.js versi 20+ diperlukan (Versi Mas: $NODE_VER)${NC}"
    exit 1
fi

# 1. ZIP Cleanup & Root Detection (Jika diekstrak dari ZIP AI Studio)
if [ -d "LUT-Studio-FIX-main" ]; then
    echo -e "${YELLOW}Mendeteksi folder ekstraksi. Memindahkan file ke root...${NC}"
    mv LUT-Studio-FIX-main/* .
    mv LUT-Studio-FIX-main/.* . 2>/dev/null
    rm -rf LUT-Studio-FIX-main
fi

# 2. Update project dari GitHub (Optional jika pakai ZIP)
if [ -d ".git" ]; then
    echo -e "${BLUE}[1/6] Sinkronisasi GitHub...${NC}"
    git add .
    git commit -m "Build Sync" &>/dev/null
    git pull origin main --rebase
fi

# 3. Install Dependensi (Legacy Peer Deps untuk kestabilan)
echo -e "${BLUE}[2/6] Menginstal Dependensi...${NC}"
npm install --legacy-peer-deps

# 4. Build UI Project
echo -e "${BLUE}[3/6] Mengompilasi Web Assets...${NC}"
npm run build

# 5. Sinkronisasi Native Android (Anti-Amnesia Logic)
echo -e "${BLUE}[4/6] Menyiapkan Folder Android...${NC}"
# Kita hapus folder android lama agar sync bersih (Anti-Rollback)
if [ -d "android" ]; then
    echo -e "${YELLOW}Refresh folder android untuk update v4.0.0...${NC}"
    rm -rf android
fi

npx cap add android
npx cap sync android

# 6. Build APK menggunakan Gradle
echo -e "${BLUE}[5/6] Memulai Kompilasi APK (Gradle)...${NC}"
export GRADLE_OPTS="-Xmx1536m -XX:MaxMetaspaceSize=512m"

if [ -d "android" ]; then
    chmod +x android/gradlew
    cd android
    # Assemble Clean
    ./gradlew clean
    ./gradlew assembleDebug --no-daemon
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ APK BUILD SUCCESS!${NC}"
        
        # Pindahkan ke Folder Download
        APK_PATH=$(find . -name "app-debug.apk" | head -1)
        DATE_TAG=$(date +'%H%M')
        APK_DEST="/sdcard/Download/LUT_STUDIO_v4_0_0_$DATE_TAG.apk"
        
        if [ -f "$APK_PATH" ]; then
            cp "$APK_PATH" "$APK_DEST"
            echo -e "${GREEN}💎 APK SIAP DIAKRAB: ${NC}"
            echo -e "${BLUE}📁 Lokasi: $APK_DEST${NC}"
        fi
    else
        echo -e "${RED}❌ GAGAL! Cek memori HP atau Java version.${NC}"
    fi
    cd ..
else
    echo -e "${RED}ERR: Folder android gagal dibuat.${NC}"
fi

# 7. Final GitHub Push
echo -ne "${BLUE}Ingin update repositori GitHub Mas Dhan? (y/n): ${NC}"
read choice
if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    git add .
    git commit -m "🚀 Complete Build v4.0.0 Master"
    git push origin main --force
    echo -e "${GREEN}✅ GitHub Updated!${NC}"
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}    MASTER v4.0.0 SUDAH SIAP DIINSTAL!   ${NC}"
echo -e "${BLUE}=========================================${NC}"
