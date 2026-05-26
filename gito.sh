#!/bin/bash

# ==========================================
# RENK VE TASARIM TANIMLAMALARI
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# ==========================================
# BAĞLAMLIK VE KONTROL FONKSİYONLARI
# ==========================================
bağımlılık_kontrolü() {
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}Hata: GitHub CLI (gh) kurulu değil! Lütfen önce yükleyin.${NC}"
        exit 1
    fi
}

oturum_kontrolü() {
    echo -e "${CYAN}Oturum durumu kontrol ediliyor...${NC}"
    if gh auth status &> /dev/null; then
        echo -e "${GREEN}✔ Aktif GitHub oturumu bulundu.${NC}"
        
        # 🔑 [RESMİ ÇÖZÜM]: Git'in gh oturumunu otomatik kullanmasını sağlayan resmi yöntem
        gh auth setup-git
        
    else
        echo -e "${YELLOW}⚠ Aktif oturum bulunamadı. Lütfen giriş yapın.${NC}"
        gh_oturum_ac
    fi
}

git_deposu_mu() {
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        echo -e "${RED}❌ Hata: Bu klasör bir Git deposu değil!${NC}"
        return 1
    fi
    return 0
}

# ==========================================
# 1. OTURUM FONKSİYONLARI
# ==========================================
gh_oturum_ac() {
    echo -e "\n${YELLOW}--> GitHub CLI Oturum Açma İşlemi <-------${NC}"
    # HTTPS protokolü ile tarayıcı tabanlı güvenli giriş başlatılır
    gh auth login --proc HTTPS --web
    
    # Giriş sonrası Git entegrasyonu
    gh auth setup-git
}

gh_oturum_kapat() {
    echo -e "\n${RED}--> Oturum Kapatılıyor... <-------${NC}"
    gh auth logout -y
}

# ==========================================
# 2. LOCAL GIT İŞLEMLERİ
# ==========================================
menu_git_yerel() {
    while true; do
        echo -e "\n${CYAN}=== YEREL GİT İŞLEMLERİ ===${NC}"
        echo "1) Git Durumunu Göster (Status)"
        echo "2) GitHub'dan Güncel Kodları Çek (PULL)"
        echo "3) Değişiklikleri Ekle, Commit Et ve Gönder (PUSH)"
        echo "4) Ana Menüye Dön"
        read -p "Seçiminiz: " git_secim

        case $git_secim in
            1) git_deposu_mu || continue; git status -s ;;
            2)
                git_deposu_mu || continue
                current_branch=$(git branch --show-current)
                echo -e "\n${YELLOW}--> GitHub'dan değişiklikler çekiliyor (${current_branch})...${NC}"
                git pull origin "$current_branch"
                ;;
            3)
                git_deposu_mu || continue
                echo -e "\nHangi dosyaları eklemek istersiniz?\n1) Tüm Değişiklikler (git add .)\n2) Belirli Bir Dosya"
                read -p "Seçiminiz [1-2]: " add_secim
                if [ "$add_secim" == "1" ]; then git add .; else read -p "Dosya yolu: " d_yolu; git add "$d_yolu"; fi

                read -p "Commit mesajı: " c_msg
                if [ -z "$c_msg" ]; then c_msg="Güncelleme ($(date +'%Y-%m-%d %H:%M'))"; fi
                git commit -m "$c_msg"

                current_branch=$(git branch --show-current)
                echo -e "${YELLOW}Kodlar gönderiliyor...${NC}"
                git push -u origin "$current_branch"
                ;;
            4) break ;;
            *) echo -e "${RED}Geçersiz seçim!${NC}" ;;
        esac
    done
}

# ==========================================
# 3. REPOSITORY (DEPO) FONKSİYONLARI
# ==========================================
menu_repo() {
    while true; do
        echo -e "\n${GREEN}=== REPOSITORY MÜHENDİSLİĞİ ===${NC}"
        echo "1) Depoları Listele (Son 50)"
        echo "2) Yeni Depo Oluştur"
        echo "3) Depo Sil"
        echo "4) Depo Forkla (Çatalla)"
        echo "5) Depoyu/Sayfayı Tarayıcıda Aç (Browse)"
        echo "6) Ana Menüye Dön"
        read -p "Seçiminiz: " r_secim
        case $r_secim in
            1) gh repo list --limit 50 ;;
            2) 
                read -p "Depo adı: " r_name
                echo -e "1) Public\n2) Private"
                read -p "Gizlilik: " r_priv
                if [ "$r_priv" == "1" ]; then gh repo create "$r_name" --public --clone; else gh repo create "$r_name" --private --clone; fi
                ;;
            3) read -p "Silinecek depo (kullanici/depo): " r_del; gh repo delete "$r_del" --confirm ;;
            4) read -p "Forklanacak depo (kullanici/depo): " r_fork; gh repo fork "$r_fork" --clone ;;
            5) echo -e "${YELLOW}Mevcut depo tarayıcıda açılıyor...${NC}"; gh browse ;;
            6) break ;;
            *) echo -e "${RED}Geçersiz seçim!${NC}" ;;
        esac
    done
}

# ==========================================
# 4. PULL REQUEST (PR) FONKSİYONLARI
# ==========================================
menu_pr() {
    while true; do
        echo -e "\n${MAGENTA}=== PULL REQUEST YÖNETİMİ ===${NC}"
        echo "1) Aktif PR'ları Listele"
        echo "2) Yeni PR Oluştur"
        echo "3) PR Checkout Et (Yerel dala çek)"
        echo "4) PR Durumunu Kontrol Et (Checks)"
        echo "5) PR İncele/Yorum Yap (Review)"
        echo "6) PR Merge Et (Birleştir)"
        echo "7) Ana Menüye Dön"
        read -p "Seçiminiz: " p_secim
        case $p_secim in
            1) gh pr list ;;
            2) git_deposu_mu || continue; current_branch=$(git branch --show-current); git push -u origin "$current_branch" 2>/dev/null; gh pr create --fill ;;
            3) read -p "Çekilecek PR Numarası: " pr_chk; gh pr checkout "$pr_chk" ;;
            4) gh pr checks ;;
            5) read -p "Review yapılacak PR No: " pr_rev; gh pr review "$pr_rev" ;;
            6) read -p "Merge edilecek PR No: " pr_num; gh pr merge "$pr_num" --merge ;;
            7) break ;;
            *) echo -e "${RED}Geçersiz seçim!${NC}" ;;
        esac
    done
}

# ==========================================
# 5. ISSUE (SORUN) FONKSİYONLARI
# ==========================================
menu_issue() {
    while true; do
        echo -e "\n${YELLOW}=== ISSUE (SORUN) YÖNETİMİ ===${NC}"
        echo "1) Issue'ları Listele"
        echo "2) Yeni Issue Aç"
        echo "3) Belirli Bir Issue Detayını Gör"
        echo "4) Issue Kapat"
        echo "5) Ana Menüye Dön"
        read -p "Seçiminiz: " i_secim
        case $i_secim in
            1) gh issue list ;;
            2) read -p "Başlık: " i_title; read -p "İçerik: " i_body; gh issue create --title "$i_title" --body "$i_body" ;;
            3) read -p "Issue Numarası: " i_num; gh issue view "$i_num" ;;
            4) read -p "Kapatılacak Issue No: " i_cls; gh issue close "$i_cls" ;;
            5) break ;;
            *) echo -e "${RED}Geçersiz seçim!${NC}" ;;
        esac
    done
}

# ==========================================
# 6. GITHUB ACTIONS & WORKFLOW FONKSİYONLARI
# ==========================================
menu_actions() {
    while true; do
        echo -e "\n${BLUE}=== GITHUB ACTIONS & WORKFLOW ===${NC}"
        echo "1) Workflow'ları Listele"
        echo "2) Bir Workflow Tetikle (Run)"
        echo "3) Son Çalışan Workflowları Listele (Runs)"
        echo "4) Canlı Çalışma Takibi Yap (Watch)"
        echo "5) Yeni Proje Sürümü (Release) Oluştur"
        echo "6) Ana Menüye Dön"
        read -p "Seçiminiz: " a_secim
        case $a_secim in
            1) gh workflow list ;;
            2) read -p "Çalıştırılacak dosya adı: " wf_name; gh workflow run "$wf_name" ;;
            3) gh run list ;;
            4) gh run watch ;;
            5) read -p "Versiyon etiketi: " rel_tag; gh release create "$rel_tag" --generate-notes ;;
            6) break ;;
            *) echo -e "${RED}Geçersiz seçim!${NC}" ;;
        esac
    done
}

# ==========================================
# 7. SİSTEM, KISAYOL, DEĞİŞKEN & GIST AYARLARI
# ==========================================
menu_sistem_gelis() {
    while true; do
        echo -e "\n${CYAN}=== SİSTEM, DEĞİŞKENLER VE GIST ===${NC}"
        echo "1) Gist'leri Listele / Gizli Gist Oluştur"
        echo "2) Aktif Codespace'leri Listele"
        echo "3) Depoya Gizli Şifre (Secret) Ekle"
        echo "4) Depoya Ortam Değişkeni (Variable) Ekle"
        echo "5) GH Komut Kısayolu (Alias) Tanımla"
        echo "6) GH Eklentisi (Extension) Yükle"
        echo "7) Ana Menüye Dön"
        read -p "Seçiminiz: " s_secim
        case $s_secim in
            1) 
                echo -e "1) Listele\n2) Dosyadan Gizli Gist Oluştur"
                read -p "Seçim: " gst; [ "$gst" == "1" ] && gh gist list || { read -p "Dosya yolu: " gf; gh gist create "$gf" -p; }
                ;;
            2) gh codespace list ;;
            3) read -p "Secret Adı: " sn; read -p "Değeri: " sv; gh secret set "$sn" --body "$sv" ;;
            4) read -p "Değişken Adı: " vn; read -p "Değeri: " vv; gh variable set "$vn" --body "$vv" ;;
            5) read -p "Kısayol adı: " al_n; read -p "Karşılık gelen komut: " al_c; gh alias set "$al_n" "$al_c" ;;
            6) read -p "Eklenti adı: " ext_n; gh extension install "$ext_n" ;;
            7) break ;;
            *) echo -e "${RED}Geçersiz seçim!${NC}" ;;
        esac
    done
}

# ==========================================
# ANA ÇALIŞMA DÖNGÜSÜ
# ==========================================
bağımlılık_kontrolü
oturum_kontrolü

while true; do
    echo -e "\n${BLUE}=====================================${NC}"
    echo -e "${YELLOW}    ULTIMATE GITHUB CLI INTERFACE    ${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo -e "1) Oturum İşlemleri (Giriş Durumu/Yenile/Çıkış)"
    echo -e "2) Yerel Git İşlemleri (Status, PULL, PUSH)"
    echo -e "3) Repository (Depo) Yönetimi"
    echo -e "4) Pull Request (PR) Yönetimi"
    echo -e "5) Issue (Sorun) Takibi"
    echo -e "6) GitHub Actions & CI/CD & Release"
    echo -e "7) Sistem, Kısayol, Değişken & Gist Ayarları"
    echo -e "8) Sistemden Çıkış"
    echo -e "${BLUE}=====================================${NC}"
    read -p "Ana Menü Seçiminiz [1-8]: " ana_secim

    case $ana_secim in
        1) 
            echo -e "\n1) Durum Göster\n2) Yeniden Giriş Yap\n3) Oturumu Kapat"
            read -p "Seçiminiz: " auth_sec
            if [ "$auth_sec" == "1" ]; then gh auth status; fi
            if [ "$auth_sec" == "2" ]; then gh_oturum_ac; fi
            if [ "$auth_sec" == "3" ]; then gh_oturum_kapat; fi
            ;;
        2) menu_git_yerel ;;
        3) menu_repo ;;
        4) menu_pr ;;
        5) menu_issue ;;
        6) menu_actions ;;
        7) menu_sistem_gelis ;;
        8) echo -e "\n${GREEN}Görüşmek üzere, harika işler çıkardınız!${NC}"; break ;;
        *) echo -e "\n${RED}Geçersiz seçim! Lütfen 1-8 arası değer girin.${NC}" ;;
    esac
done
