;***********************************************************************
; DENEY 2 - 4x4 KEYPAD ile 4-LED BINARY SAYAC
;***********************************************************************
; Mikrodenetleyici : PIC16F628A
; Osilatör         : Dahili RC (INTRC), ~4MHz
; Geliştirme Aracı : MPLAB IDE + MicroPro Programlayıcı
;***********************************************************************
;
; DEVRE BAĞLANTILARI (Şekil 2.1'e göre):
;
;   PORTA:
;     RA0 ─── LED0 ─── 470Ω ─── +5V   (Bit0 / LSB)
;     RA1 ─── LED1 ─── 470Ω ─── +5V   (Bit1)
;     RA2 ─── LED2 ─── 470Ω ─── +5V   (Bit2)
;     RA3 ─── LED3 ─── 470Ω ─── +5V   (Bit3 / MSB)
;     (* High-Aktif: RA=1 → LED yanar *)
;
;   PORTB - KEYPAD Modülü (10K pull-up mevcut):
;     RB0 ─── Sütun 0 (1,4,7,*)    ┐
;     RB1 ─── Sütun 1 (2,5,8,0)    ├── ÇIKIŞ (0 sürülür, tarama)
;     RB2 ─── Sütun 2 (3,6,9,#)    │
;     RB3 ─── Sütun 3 (A,B,C,D)    ┘
;     RB4 ─── Satır 0 (1,2,3,A)    ┐
;     RB5 ─── Satır 1 (4,5,6,B)    ├── GİRİŞ (okunur)
;     RB6 ─── Satır 2 (7,8,9,C)    │
;     RB7 ─── Satır 3 (*,0,#,D)    ┘
;
; ÇALIŞMA MANTIĞI:
;   Herhangi bir tuşa her basışta binary sayaç 1 artar.
;   Sayaç: 0 → 1 → 2 → ... → 15 → 0 → ... (döngüsel)
;   LED gösterimi:
;     LED3(RA3) LED2(RA2) LED1(RA1) LED0(RA0)
;      MSB                            LSB
;   Örnek: 5 → 0101 → RA3=0, RA2=1, RA1=0, RA0=1
;
;***********************************************************************

        LIST    P=16F628A
        #INCLUDE <P16F628A.INC>

        ; -------------------------------------------------------
        ; KONFİGÜRASYON BİTLERİ
        ; -------------------------------------------------------
        __CONFIG _CP_OFF & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BODEN_OFF & _LVP_OFF & _INTRC_OSC_NOCLKOUT
        ;
        ; _CP_OFF              : Kod koruma KAPALI
        ; _WDT_OFF             : Watchdog Timer KAPALI
        ; _PWRTE_ON            : Power-up Timer AÇIK (72ms reset gecikmesi)
        ; _MCLRE_ON            : MCLR pini aktif (RA5 = Reset)
        ; _BODEN_OFF           : Brown-out Reset KAPALI
        ; _LVP_OFF             : Düşük Gerilimli Programlama KAPALI
        ; _INTRC_OSC_NOCLKOUT  : Dahili RC Osilatör, RA6/RA7 = I/O

        ; -------------------------------------------------------
        ; DEĞİŞKEN TANIMLARI (Genel Amaçlı RAM: 0x20 - 0x7F)
        ; -------------------------------------------------------
        CBLOCK  0x20
            COUNTER     ; Binary sayaç (0-15 arası değer tutar)
            DLY_OUT     ; Gecikme - dış döngü sayacı
            DLY_IN      ; Gecikme - iç döngü sayacı
        ENDC

        ; -------------------------------------------------------
        ; KISALTMA / EQU TANIMLARI
        ; -------------------------------------------------------
ROW_MASK    EQU     0xF0    ; RB4-RB7 (Satır) maskesi
COL_ALL_LO  EQU     0x00    ; Tüm sütunlar LOW (0): tarama pozisyonu

;***********************************************************************
; VEKTÖRLER
;***********************************************************************
        ORG     0x0000          ; Reset Vektörü
        GOTO    INIT

        ORG     0x0004          ; Kesme Vektörü (kullanılmıyor)
        RETFIE

;***********************************************************************
; INIT: BAŞLATMA RUTİNİ
;***********************************************************************
INIT:
        ; --- Comparatörleri kapat (RA0-RA3 dijital I/O olsun) ---
        MOVLW   0x07
        MOVWF   CMCON           ; CM2:CM0 = 111 → Comparatörler devre dışı

        ; --- BANK 1: TRIS ve OPTION ayarları ---
        BANKSEL TRISA
        CLRF    TRISA           ; PORTA: RA0-RA7 → Tümü ÇIKIŞ (LED sürücü)

        MOVLW   b'11110000'     ; RB7:RB4 = 1 (Giriş / Satırlar)
        MOVWF   TRISB           ; RB3:RB0 = 0 (Çıkış / Sütunlar)

        MOVLW   b'01111111'     ; Bit7 (RBPU) = 0 → RB dahili pull-up'lar AKTİF
        MOVWF   OPTION_REG      ; (Keypad 10K dış pull-up ile paralel çalışır)

        ; --- BANK 0: Port başlangıç değerleri ---
        BANKSEL PORTA
        CLRF    PORTA           ; Tüm LEDler söndür (RA0-RA3 = 0)
        MOVLW   COL_ALL_LO      ; Sütunlar LOW: taramaya hazır
        MOVWF   PORTB

        ; --- Sayacı sıfırla ---
        CLRF    COUNTER         ; COUNTER = 0 (Başlangıç: 0000b)

        ; --- Başlangıç değerini LED'lere yaz ---
        MOVF    COUNTER, W
        MOVWF   PORTA           ; LED göster: 0000 (hepsi söndük)

;***********************************************************************
; ANA PROGRAM DÖNGÜSÜ
;***********************************************************************
MAIN_LOOP:
        ;------------------------------------------------------------
        ; ADIM 1: Herhangi bir tuşa basılana kadar bekle
        ;------------------------------------------------------------
        CALL    WAIT_KEY

        ;------------------------------------------------------------
        ; ADIM 2: Sayacı 1 artır, 16 olunca sıfırla (0-15 döngüsü)
        ;------------------------------------------------------------
        INCF    COUNTER, F      ; COUNTER = COUNTER + 1

        MOVF    COUNTER, W      ; W = COUNTER
        SUBLW   0x10            ; W = 16 - COUNTER
        BTFSC   STATUS, Z       ; Z=1 ise COUNTER=16
        CLRF    COUNTER         ;   → Sıfırla (16 → 0)

        ;------------------------------------------------------------
        ; ADIM 3: Güncel sayaç değerini LED'lere yaz
        ;   RA3(MSB)  RA2     RA1     RA0(LSB)
        ;    Bit3     Bit2    Bit1    Bit0
        ;------------------------------------------------------------
        MOVF    COUNTER, W
        ANDLW   0x0F            ; Güvenli: sadece alt 4 bit
        MOVWF   PORTA           ; LED'lere yaz

        ;------------------------------------------------------------
        ; ADIM 4: Tuşun bırakılmasını bekle (titreşim giderme)
        ;------------------------------------------------------------
        CALL    WAIT_RELEASE

        GOTO    MAIN_LOOP       ; Ana döngüye dön

;***********************************************************************
; WAIT_KEY: TUŞA BASILANA KADAR BEKLE (Debounce dahil)
;***********************************************************************
; Tüm sütunları LOW sürer, satır pinlerini okur.
; RB4-RB7'den herhangi biri LOW olursa tuş basılmış demektir.
; 20ms debounce: gürültü ile gerçek basışı ayırt eder.
;***********************************************************************
WAIT_KEY:
        MOVLW   COL_ALL_LO
        MOVWF   PORTB           ; Tüm sütunlar LOW

SCAN_PRESS:
        MOVF    PORTB, W        ; Port B'yi oku
        ANDLW   ROW_MASK        ; Sadece satır pinleri (RB4-RB7)
        XORLW   ROW_MASK        ; 0xF0 XOR 0xF0 = 0 → hiç tuş yok (Z=1)
        BTFSC   STATUS, Z
        GOTO    SCAN_PRESS      ; Tuş tespit edilmedi, taramaya devam

        ; Tuş var gibi görünüyor → 20ms bekle (titreşim filtresi)
        CALL    DELAY_20MS

        ; Tekrar kontrol: hala basılı mı?
        MOVF    PORTB, W
        ANDLW   ROW_MASK
        XORLW   ROW_MASK
        BTFSC   STATUS, Z
        GOTO    SCAN_PRESS      ; Gürültüydü → yeniden başa dön

        RETURN                  ; Gerçek tuş basışı onaylandı!

;***********************************************************************
; WAIT_RELEASE: TUŞUN BIRAKILMASINı BEKLE (Debounce dahil)
;***********************************************************************
; Sayaç güncellemesi sonrası aynı tuşun tekrar sayılmasını önler.
;***********************************************************************
WAIT_RELEASE:
        MOVLW   COL_ALL_LO
        MOVWF   PORTB           ; Tüm sütunlar LOW

SCAN_RELEASE:
        MOVF    PORTB, W
        ANDLW   ROW_MASK
        XORLW   ROW_MASK        ; 0 → tuş hala basılı (Z=0)
        BTFSS   STATUS, Z       ; Z=1 → tüm satırlar HIGH = tuş bırakıldı
        GOTO    SCAN_RELEASE    ; Hala basılı, bekle

        ; Tuş bırakıldı → 20ms son debounce
        CALL    DELAY_20MS
        RETURN

;***********************************************************************
; DELAY_20MS: YAKLASIK 20ms GECİKME (@4MHz dahili osilatör)
;***********************************************************************
; 4MHz → 1 instruction cycle = 1µs
;
; İç döngü (DLOOP_IN):
;   NOP      = 1 cy
;   DECFSZ   = 1 cy (son adımda 2 cy)
;   GOTO     = 2 cy
;   Toplam   ≈ 4 cy × 200 = 800 cy = 800µs
;
; Dış döngü (DLOOP_OUT): 25 tekrar
;   25 × 800µs = 20.000µs ≈ 20ms
;
; (MOVWF, DECFSZ(son), RETURN overhead ~küçük, ihmal edilebilir)
;***********************************************************************
DELAY_20MS:
        MOVLW   .25
        MOVWF   DLY_OUT         ; Dış döngü: 25 tur

DLOOP_OUT:
        MOVLW   .200
        MOVWF   DLY_IN          ; İç döngü: 200 tur

DLOOP_IN:
        NOP                     ; 1 cycle - zamanlama dolgusu
        DECFSZ  DLY_IN, F       ; 1 cycle (son: 2 cy) - iç sayaç azalt
        GOTO    DLOOP_IN        ; 2 cycle - iç döngü devam
        DECFSZ  DLY_OUT, F      ; Dış sayaç azalt
        GOTO    DLOOP_OUT       ; Dış döngü devam
        RETURN

;***********************************************************************
        END
;***********************************************************************
;
; ÖRNEK LED GÖSTERİM TABLOSU (Her tuş basışında sıradaki değer):
;
; Sayaç | RA3 RA2 RA1 RA0 | Onluk
; ------+------------------+------
;   0   |  0   0   0   0  |   0   (hepsi söndük)
;   1   |  0   0   0   1  |   1
;   2   |  0   0   1   0  |   2
;   3   |  0   0   1   1  |   3
;   4   |  0   1   0   0  |   4
;   5   |  0   1   0   1  |   5
;   6   |  0   1   1   0  |   6
;   7   |  0   1   1   1  |   7
;   8   |  1   0   0   0  |   8
;   9   |  1   0   0   1  |   9
;  10   |  1   0   1   0  |  10
;  11   |  1   0   1   1  |  11
;  12   |  1   1   0   0  |  12
;  13   |  1   1   0   1  |  13
;  14   |  1   1   1   0  |  14
;  15   |  1   1   1   1  |  15  (hepsi yandı)
;  → 0  |  0   0   0   0  |   0  (otomatik sıfırla)
;
;***********************************************************************
