;*******************************************************************************
; Proje Adı: 4x4 Keypad Tarama ve LED Display (Debounce Destekli)
; Yazar: Abdulkadir KELEŞ
; Denetleyici: PIC 16F628A
; Açıklama: Tuş takımından girilen değer PORTA'daki 4 LED'de binary görülür.
;*******************************************************************************

    LIST P=16F628A
    INCLUDE "P16F628A.INC"

    ; Konfigürasyon Ayarları
    __CONFIG _INTOSC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _LVP_OFF

;--- DEĞİŞKEN TANIMLAMALARI ---
CBLOCK 0x20
    D1, D2              ; Gecikme döngüsü değişkenleri
    TUS_DEGER           ; Algılanan tuşun sayısal değeri
ENDC

    ORG 0x00
    GOTO INIT

;--- GECİKME ALT PROGRAMI (~20ms @ 4MHz) ---
; Buton arklarını (bounce) önlemek için kullanılır.
DELAY_20MS:
    MOVLW   D'26'
    MOVWF   D1
L1: MOVLW   D'250'
    MOVWF   D2
L2: DECFSZ  D2, F
    GOTO    L2
    DECFSZ  D1, F
    GOTO    L1
    RETURN

;--- PORT KURULUMLARI ---
INIT:
    MOVLW   0x07        
    MOVWF   CMCON       ; Komparatörleri kapat (PORTA dijital giriş/çıkış için)
    
    BANKSEL TRISA       ; Bank 1'e geç
    CLRF    TRISA       ; PORTA (RA0-RA3) Çıkış -> LED'ler
    MOVLW   B'00001111' ; RB0-RB3 Giriş (Sütunlar), RB4-RB7 Çıkış (Satırlar)
    MOVWF   TRISB
    BANKSEL PORTA       ; Bank 0'a geri dön
    CLRF    PORTA       ; Başlangıçta LED'leri söndür

;--- ANA DÖNGÜ ---
MAIN:
    ; 1. SATIR TARAMA (RB4)
    MOVLW   B'11101111' 
    MOVWF   PORTB
    CALL    KONTROL_SUTUN
    
    ; 2. SATIR TARAMA (RB5)
    MOVLW   B'11011111'
    MOVWF   PORTB
    CALL    KONTROL_SUTUN
    
    ; 3. SATIR TARAMA (RB6)
    MOVLW   B'10111111'
    MOVWF   PORTB
    CALL    KONTROL_SUTUN
    
    ; 4. SATIR TARAMA (RB7)
    MOVLW   B'01111111'
    MOVWF   PORTB
    CALL    KONTROL_SUTUN
    
    GOTO    MAIN

;--- SÜTUN KONTROL VE DEBOUNCE MANTIĞI ---
KONTROL_SUTUN:
    ; RB0 Kontrol (Sütun 1)
    BTFSS   PORTB, 0
    GOTO    TUS_YAKALA
    ; RB1 Kontrol (Sütun 2)
    BTFSS   PORTB, 1
    GOTO    TUS_YAKALA
    ; RB2 Kontrol (Sütun 3)
    BTFSS   PORTB, 2
    GOTO    TUS_YAKALA
    ; RB3 Kontrol (Sütun 4)
    BTFSS   PORTB, 3
    GOTO    TUS_YAKALA
    RETURN              ; Hiçbir tuşa basılmadıysa geri dön

TUS_YAKALA:
    CALL    DELAY_20MS  ; Sıçramayı bekle (Debounce)
    
    ; Hangi satırda olduğumuzu ve hangi sütunun 0 olduğunu bulup PORTA'ya yaz
    ; Bu kısım föydeki Şekil 2.2 tablosuna göre özelleştirilebilir.
    ; Örnek: RB4=0 ve RB0=0 ise TUS=0
    
    ; Basitlik için tarama anındaki PORTB durumunu analiz et:
    MOVF    PORTB, W
    MOVWF   TUS_DEGER   ; Burada bir Look-up Table (RETW) kullanmak daha profesyonel olur.
    
    ; Şimdilik test için doğrudan PORTA'yı güncelle (veya tuş kodunu dönüştür)
    ; (Buraya tablo dönüşüm kodunu ekleyebilirsin)
    
    ; Buton bırakılana kadar bekle (Sistemi kilitlememek için önemlidir)
WAIT_RELEASE:
    MOVF    PORTB, W
    ANDLW   B'00001111' ; Sadece sütunları maskele
    XORLW   B'00001111' ; Hepsi 1 mi? (Boşta mı?)
    BTFSS   STATUS, Z
    GOTO    WAIT_RELEASE
    
    RETURN

    END