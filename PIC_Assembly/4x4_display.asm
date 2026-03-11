LIST P=16F628A
    INCLUDE "p16f628a.inc"
    __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_OFF & _LVP_OFF & _CP_OFF

    ; --- DEĞİŞKEN TANIMLAMALARI ---
    CBLOCK 0x20
    SAYAC1
    SAYAC2
    SAYAC3
    ENDC

    ORG 0x00
    GOTO MAIN

MAIN
    ; Bank 1'e geçiş
    MOVLW   h'20'
    MOVWF   STATUS

    ; PORTA (LED'ler) tamamı çıkış (0)
    MOVLW   h'00'
    MOVWF   TRISA

    ; PORTB: RB0-RB3 Çıkış (Satırlar - 0), RB4-RB7 Giriş (Sütunlar - 1)
    MOVLW   h'F0'
    MOVWF   TRISB

    ; PORTB Pull-up dirençlerini aktif et (OPTION_REG 7. bit = 0)
    MOVLW   b'01111111'
    MOVWF   OPTION_REG

    ; Bank 0'a dönüş
    MOVLW   h'00'
    MOVWF   STATUS

    ; PORTA Analog karşılaştırıcıları kapat (Dijital I/O için)
    MOVLW   h'07'
    MOVWF   CMCON

    ; Portların ilk durumlarını sıfırla
    MOVLW   h'00'
    MOVWF   PORTA
    MOVLW   h'FF'
    MOVWF   PORTB

ANA_DONGU
    ; --- 1. SATIR TARAMASI (RB0 = 0) ---
    MOVLW   b'11111110'
    MOVWF   PORTB
    BTFSS   PORTB, 4        ; 1. Sütun kontrolü
    GOTO    TUS_1
    BTFSS   PORTB, 5        ; 2. Sütun kontrolü
    GOTO    TUS_2
    BTFSS   PORTB, 6        ; 3. Sütun kontrolü
    GOTO    TUS_3
    BTFSS   PORTB, 7        ; 4. Sütun kontrolü
    GOTO    TUS_A

    ; --- 2. SATIR TARAMASI (RB1 = 0) ---
    MOVLW   b'11111101'
    MOVWF   PORTB
    BTFSS   PORTB, 4
    GOTO    TUS_4
    BTFSS   PORTB, 5
    GOTO    TUS_5
    BTFSS   PORTB, 6
    GOTO    TUS_6
    BTFSS   PORTB, 7
    GOTO    TUS_B

    ; --- 3. SATIR TARAMASI (RB2 = 0) ---
    MOVLW   b'11111011'
    MOVWF   PORTB
    BTFSS   PORTB, 4
    GOTO    TUS_7
    BTFSS   PORTB, 5
    GOTO    TUS_8
    BTFSS   PORTB, 6
    GOTO    TUS_9
    BTFSS   PORTB, 7
    GOTO    TUS_C

    ; --- 4. SATIR TARAMASI (RB3 = 0) ---
    MOVLW   b'11110111'
    MOVWF   PORTB
    BTFSS   PORTB, 4
    GOTO    TUS_YILDIZ
    BTFSS   PORTB, 5
    GOTO    TUS_0
    BTFSS   PORTB, 6
    GOTO    TUS_KARE
    BTFSS   PORTB, 7
    GOTO    TUS_D

    GOTO    ANA_DONGU       ; Tuşa basılmadıysa taramaya devam et

; --- TUŞ ATAMALARI VE LED GÖSTERİMİ ---
TUS_0:      MOVLW b'00000000' 
            GOTO GOSTER
TUS_1:      MOVLW b'00000001' 
            GOTO GOSTER
TUS_2:      MOVLW b'00000010' 
            GOTO GOSTER
TUS_3:      MOVLW b'00000011' 
            GOTO GOSTER
TUS_4:      MOVLW b'00000100' 
            GOTO GOSTER
TUS_5:      MOVLW b'00000101' 
            GOTO GOSTER
TUS_6:      MOVLW b'00000110' 
            GOTO GOSTER
TUS_7:      MOVLW b'00000111' 
            GOTO GOSTER
TUS_8:      MOVLW b'00001000' 
            GOTO GOSTER
TUS_9:      MOVLW b'00001001' 
            GOTO GOSTER
TUS_A:      MOVLW b'00001010' 
            GOTO GOSTER
TUS_B:      MOVLW b'00001011' 
            GOTO GOSTER
TUS_C:      MOVLW b'00001100' 
            GOTO GOSTER
TUS_D:      MOVLW b'00001101' 
            GOTO GOSTER
TUS_YILDIZ: MOVLW b'00001110'  ; Yıldız için 14 (E)
            GOTO GOSTER
TUS_KARE:   MOVLW b'00001111'  ; Kare için 15 (F)
            GOTO GOSTER

GOSTER
    MOVWF   PORTA           ; W kaydedicisindeki değeri LED'lere aktar
    CALL    GECIKME         ; 1 saniye bekle
    MOVLW   h'00'
    MOVWF   PORTA           ; Bekleme bitince LED'leri söndür
    GOTO    ANA_DONGU       ; Yeni tuş için taramaya dön

; --- 1 SANİYELİK GECİKME ALT PROGRAMI ---
GECIKME
    MOVLW   d'6'            ; Dıştaki döngü çarpanı
    MOVWF   SAYAC3
GEC_DONGU3
    MOVLW   d'255'          ; Ortadaki döngü çarpanı
    MOVWF   SAYAC2
GEC_DONGU2
    MOVLW   d'255'          ; İçteki döngü çarpanı
    MOVWF   SAYAC1
GEC_DONGU1
    DECFSZ  SAYAC1, F       ; SAYAC1'i 1 azalt, 0 olursa atla
    GOTO    GEC_DONGU1      ; 0 değilse devam et
    
    DECFSZ  SAYAC2, F       ; SAYAC2'yi 1 azalt, 0 olursa atla
    GOTO    GEC_DONGU2      ; 0 değilse devam et
    
    DECFSZ  SAYAC3, F       ; SAYAC3'ü 1 azalt, 0 olursa atla
    GOTO    GEC_DONGU3      ; 0 değilse devam et
    
    RETURN                  ; 1 saniye doldu, çağrıldığı yere geri dön

    END
