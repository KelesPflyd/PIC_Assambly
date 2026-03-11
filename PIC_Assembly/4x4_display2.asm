LIST P=16F628A
    INCLUDE "p16f628a.inc"
    
    ; Konfigürasyon ayarları
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
    ; 1. Bank 1'e geçiş
    MOVLW   h'20'
    MOVWF   STATUS

    ; 2. PORTA Ayarları: Tamamı çıkış (LED'ler için)
    MOVLW   h'00'
    MOVWF   TRISA

    ; 3. PORTB Ayarları: RB0-RB3 Çıkış (Satırlar), RB4-RB7 Giriş (Sütunlar)
    MOVLW   h'F0'
    MOVWF   TRISB

    ; 4. PORTB Dahili Pull-Up dirençlerini aktif et (OPTION_REG 7. bit = 0)
    MOVLW   b'01111111'
    MOVWF   OPTION_REG

    ; 5. Bank 0'a dönüş
    MOVLW   h'00'
    MOVWF   STATUS

    ; 6. PORTA Analog karşılaştırıcıları kapat, dijital (I/O) yap
    MOVLW   h'07'
    MOVWF   CMCON

    ; 7. Başlangıçta portları temizle (LED'leri söndür, satırları 1 yap)
    MOVLW   h'00'
    MOVWF   PORTA
    MOVLW   h'FF'
    MOVWF   PORTB

ANA_DONGU
    ; --- 1. SATIR TARAMASI (RB0 = 0) ---
    MOVLW   b'11111110'
    MOVWF   PORTB
    NOP                     ; Sinyalin donanımsal olarak oturması için 1 saykıl bekle
    BTFSS   PORTB, 4        ; Sütun 1 (Tuş '1')
    GOTO    TUS_1
    BTFSS   PORTB, 5        ; Sütun 2 (Tuş '2')
    GOTO    TUS_2
    BTFSS   PORTB, 6        ; Sütun 3 (Tuş '3')
    GOTO    TUS_3
    BTFSS   PORTB, 7        ; Sütun 4 (Tuş 'A')
    GOTO    TUS_A

    ; --- 2. SATIR TARAMASI (RB1 = 0) ---
    MOVLW   b'11111101'
    MOVWF   PORTB
    NOP
    BTFSS   PORTB, 4        ; Sütun 1 (Tuş '4')
    GOTO    TUS_4
    BTFSS   PORTB, 5        ; Sütun 2 (Tuş '5')
    GOTO    TUS_5
    BTFSS   PORTB, 6        ; Sütun 3 (Tuş '6')
    GOTO    TUS_6
    BTFSS   PORTB, 7        ; Sütun 4 (Tuş 'B')
    GOTO    TUS_B

    ; --- 3. SATIR TARAMASI (RB2 = 0) ---
    MOVLW   b'11111011'
    MOVWF   PORTB
    NOP
    BTFSS   PORTB, 4        ; Sütun 1 (Tuş '7')
    GOTO    TUS_7
    BTFSS   PORTB, 5        ; Sütun 2 (Tuş '8')
    GOTO    TUS_8
    BTFSS   PORTB, 6        ; Sütun 3 (Tuş '9')
    GOTO    TUS_9
    BTFSS   PORTB, 7        ; Sütun 4 (Tuş 'C')
    GOTO    TUS_C

    ; --- 4. SATIR TARAMASI (RB3 = 0) ---
    MOVLW   b'11110111'
    MOVWF   PORTB
    NOP
    BTFSS   PORTB, 4        ; Sütun 1 (Tuş '*')
    GOTO    TUS_YILDIZ
    BTFSS   PORTB, 5        ; Sütun 2 (Tuş '0')
    GOTO    TUS_0
    BTFSS   PORTB, 6        ; Sütun 3 (Tuş '#')
    GOTO    TUS_KARE
    BTFSS   PORTB, 7        ; Sütun 4 (Tuş 'D')
    GOTO    TUS_D

    GOTO    ANA_DONGU       ; Hiçbir tuşa basılmadıysa taramaya devam et

; --- TUŞ DEĞER ATAMALARI ---
TUS_0:      MOVLW h'00' 
            GOTO GOSTER
TUS_1:      MOVLW h'01' 
            GOTO GOSTER
TUS_2:      MOVLW h'02' 
            GOTO GOSTER
TUS_3:      MOVLW h'03' 
            GOTO GOSTER
TUS_4:      MOVLW h'04' 
            GOTO GOSTER
TUS_5:      MOVLW h'05' 
            GOTO GOSTER
TUS_6:      MOVLW h'06' 
            GOTO GOSTER
TUS_7:      MOVLW h'07' 
            GOTO GOSTER
TUS_8:      MOVLW h'08' 
            GOTO GOSTER
TUS_9:      MOVLW h'09' 
            GOTO GOSTER
TUS_A:      MOVLW h'0A' 
            GOTO GOSTER
TUS_B:      MOVLW h'0B' 
            GOTO GOSTER
TUS_C:      MOVLW h'0C' 
            GOTO GOSTER
TUS_D:      MOVLW h'0D' 
            GOTO GOSTER
TUS_YILDIZ: MOVLW h'0E'  ; Yıldız için 14 (E)
            GOTO GOSTER
TUS_KARE:   MOVLW h'0F'  ; Kare için 15 (F)
            GOTO GOSTER

GOSTER
    MOVWF   PORTA           ; W kaydedicisindeki değeri LED'lere aktar
    CALL    GECIKME         ; LED'in yanık kalması ve debounce için bekle (~1 sn)
    MOVLW   h'00'
    MOVWF   PORTA           ; Bekleme bitince LED'leri söndür
    GOTO    ANA_DONGU       ; Yeni tuş için taramaya dön

; --- 1 SANİYELİK GECİKME ALT PROGRAMI ---
GECIKME
    MOVLW   d'6'            
    MOVWF   SAYAC3
GEC_DONGU3
    MOVLW   d'255'          
    MOVWF   SAYAC2
GEC_DONGU2
    MOVLW   d'255'          
    MOVWF   SAYAC1
GEC_DONGU1
    DECFSZ  SAYAC1, F       
    GOTO    GEC_DONGU1      
    
    DECFSZ  SAYAC2, F       
    GOTO    GEC_DONGU2      
    
    DECFSZ  SAYAC3, F       
    GOTO    GEC_DONGU3      
    
    RETURN                  

    END