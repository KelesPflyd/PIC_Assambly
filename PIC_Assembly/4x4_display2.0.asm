; PIC16F628A 4x4 Keypad'den 4'lü LED'e Binary Çıktı
; Derleyici: MPASM

    LIST P=16F628A
    #INCLUDE <P16F628A.INC>

    ; Konfigürasyon ayarları (Dahili osilatör aktif, Watchdog kapalı)
    __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

    ; Değişken Tanımlamaları
    CBLOCK 0x20
        DELAY_VAR1
        DELAY_VAR2
    ENDC

    ORG 0x000
    GOTO BASLA

BASLA
    ; 1. PORTA'daki analog karşılaştırıcıları kapat, pinleri dijital (I/O) yap
    MOVLW 0x07
    MOVWF CMCON

    ; 2. Bank 1'e geç (TRIS ve OPTION_REG ayarları için)
    BSF STATUS, RP0

    ; 3. PORTA Ayarları: RA0-RA3 Çıkış (LED'ler), diğerleri giriş
    MOVLW b'11110000' 
    MOVWF TRISA

    ; 4. PORTB Ayarları: RB0-RB3 Çıkış (Satırlar), RB4-RB7 Giriş (Sütunlar)
    MOVLW b'11110000'
    MOVWF TRISB

    ; 5. PORTB Dahili Pull-Up dirençlerini aktif et (OPTION_REG 7. bit = 0)
    BCF OPTION_REG, 7

    ; 6. Bank 0'a dön
    BCF STATUS, RP0

    ; Başlangıçta tüm LED'leri söndür
    CLRF PORTA

ANA_DONGU
    ; --- 1. SATIR TARAMASI (Sadece RB0 = 0, diğer satırlar 1) ---
    MOVLW b'11111110'
    MOVWF PORTB
    NOP             ; Pin durumunun oturması için 1 saykıl bekle
    BTFSS PORTB, 4  ; Sütun 1 (Tuş '1' mi?) -> Basıldıysa 0 olur, atlamaz.
    GOTO TUS_1
    BTFSS PORTB, 5  ; Sütun 2 (Tuş '2' mi?)
    GOTO TUS_2
    BTFSS PORTB, 6  ; Sütun 3 (Tuş '3' mi?)
    GOTO TUS_3
    BTFSS PORTB, 7  ; Sütun 4 (Tuş 'A' mi? -> 10)
    GOTO TUS_A

    ; --- 2. SATIR TARAMASI (Sadece RB1 = 0) ---
    MOVLW b'11111101'
    MOVWF PORTB
    NOP
    BTFSS PORTB, 4  ; Sütun 1 (Tuş '4')
    GOTO TUS_4
    BTFSS PORTB, 5  ; Sütun 2 (Tuş '5')
    GOTO TUS_5
    BTFSS PORTB, 6  ; Sütun 3 (Tuş '6')
    GOTO TUS_6
    BTFSS PORTB, 7  ; Sütun 4 (Tuş 'B' -> 11)
    GOTO TUS_B

    ; --- 3. SATIR TARAMASI (Sadece RB2 = 0) ---
    MOVLW b'11111011'
    MOVWF PORTB
    NOP
    BTFSS PORTB, 4  ; Sütun 1 (Tuş '7')
    GOTO TUS_7
    BTFSS PORTB, 5  ; Sütun 2 (Tuş '8')
    GOTO TUS_8
    BTFSS PORTB, 6  ; Sütun 3 (Tuş '9')
    GOTO TUS_9
    BTFSS PORTB, 7  ; Sütun 4 (Tuş 'C' -> 12)
    GOTO TUS_C

    ; --- 4. SATIR TARAMASI (Sadece RB3 = 0) ---
    MOVLW b'11110111'
    MOVWF PORTB
    NOP
    BTFSS PORTB, 4  ; Sütun 1 (Tuş '*' -> 14 olarak gösterelim)
    GOTO TUS_YILDIZ
    BTFSS PORTB, 5  ; Sütun 2 (Tuş '0')
    GOTO TUS_0
    BTFSS PORTB, 6  ; Sütun 3 (Tuş '#' -> 15 olarak gösterelim)
    GOTO TUS_KARE
    BTFSS PORTB, 7  ; Sütun 4 (Tuş 'D' -> 13)
    GOTO TUS_D

    GOTO ANA_DONGU  ; Hiçbir tuşa basılmadıysa taramaya baştan başla

; --- TUŞ DEĞER ATAMALARI ---
TUS_0:      MOVLW 0x00 ; Binary: 0000
            GOTO GOSTER
TUS_1:      MOVLW 0x01 ; Binary: 0001
            GOTO GOSTER
TUS_2:      MOVLW 0x02 ; Binary: 0010
            GOTO GOSTER
TUS_3:      MOVLW 0x03 ; Binary: 0011
            GOTO GOSTER
TUS_4:      MOVLW 0x04 ; Binary: 0100
            GOTO GOSTER
TUS_5:      MOVLW 0x05 ; Binary: 0101
            GOTO GOSTER
TUS_6:      MOVLW 0x06 ; Binary: 0110
            GOTO GOSTER
TUS_7:      MOVLW 0x07 ; Binary: 0111
            GOTO GOSTER
TUS_8:      MOVLW 0x08 ; Binary: 1000
            GOTO GOSTER
TUS_9:      MOVLW 0x09 ; Binary: 1001
            GOTO GOSTER
TUS_A:      MOVLW 0x0A ; Binary: 1010
            GOTO GOSTER
TUS_B:      MOVLW 0x0B ; Binary: 1011
            GOTO GOSTER
TUS_C:      MOVLW 0x0C ; Binary: 1100
            GOTO GOSTER
TUS_D:      MOVLW 0x0D ; Binary: 1101
            GOTO GOSTER
TUS_YILDIZ: MOVLW 0x0E ; Binary: 1110 (Yıldız için)
            GOTO GOSTER
TUS_KARE:   MOVLW 0x0F ; Binary: 1111 (Kare için)
            GOTO GOSTER

GOSTER
    MOVWF PORTA      ; W kaydedicisindeki sayısal değeri LED'lere yaz
    CALL GECIKME     ; Debounce (Tuş sıçramasını/titreşimini engellemek için)
    CALL GECIKME     ; Tuşun bırakılmasını veya stabil kalmasını bekle
    GOTO ANA_DONGU   ; Yeni tuş okumak için başa dön

; --- GECİKME ALT PROGRAMI ---
GECIKME
    MOVLW 0xFF
    MOVWF DELAY_VAR1
G1
    MOVLW 0xFF
    MOVWF DELAY_VAR2
G2
    DECFSZ DELAY_VAR2, F
    GOTO G2
    DECFSZ DELAY_VAR1, F
    GOTO G1
    RETURN

    END