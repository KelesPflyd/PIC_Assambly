; ==============================================================================
; Hedef İşlemci : PIC16F628A
; İşlev         : 4x4 Keypad'den okunan değeri PORTA'daki LED'lere binary yansıtma
; ==============================================================================

    LIST P=16F628A
    INCLUDE "P16F628A.INC"

    __CONFIG _INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _LVP_OFF

    ORG 0x00
    GOTO BASLA

; ------------------------------------------------------------------------------
BASLA
    ; Komparatörleri kapat (PORTA dijital olsun)
    MOVLW 0x07
    MOVWF CMCON

    ; Bank1'e geç
    BSF STATUS, RP0

    ; PORTB ayarı (RB0-3 çıkış, RB4-7 giriş)
    MOVLW b'11110000'
    MOVWF TRISB

    ; Pull-up aktif
    BCF OPTION_REG, 7

    ; PORTA (RA0-RA3 çıkış)
    MOVLW b'11110000'
    MOVWF TRISA

    ; Bank0'a dön
    BCF STATUS, RP0

    ; LED'leri kapat
    CLRF PORTA

; ------------------------------------------------------------------------------
ANA_DONGU

    ; 1. sütun
    MOVLW b'11111110'
    MOVWF PORTB
    NOP

    BTFSS PORTB,4
    CALL TUS_0
    BTFSS PORTB,5
    CALL TUS_4
    BTFSS PORTB,6
    CALL TUS_8
    BTFSS PORTB,7
    CALL TUS_C

    ; 2. sütun
    MOVLW b'11111101'
    MOVWF PORTB
    NOP

    BTFSS PORTB,4
    CALL TUS_1
    BTFSS PORTB,5
    CALL TUS_5
    BTFSS PORTB,6
    CALL TUS_9
    BTFSS PORTB,7
    CALL TUS_D

    ; 3. sütun
    MOVLW b'11111011'
    MOVWF PORTB
    NOP

    BTFSS PORTB,4
    CALL TUS_2
    BTFSS PORTB,5
    CALL TUS_6
    BTFSS PORTB,6
    CALL TUS_A
    BTFSS PORTB,7
    CALL TUS_E

    ; 4. sütun
    MOVLW b'11110111'
    MOVWF PORTB
    NOP

    BTFSS PORTB,4
    CALL TUS_3
    BTFSS PORTB,5
    CALL TUS_7
    BTFSS PORTB,6
    CALL TUS_B
    BTFSS PORTB,7
    CALL TUS_F

    GOTO ANA_DONGU

; ------------------------------------------------------------------------------
; TUŞ ALT PROGRAMLARI
TUS_0
    MOVLW 0x00
    GOTO EKRANA_YAZ

TUS_1
    MOVLW 0x01
    GOTO EKRANA_YAZ

TUS_2
    MOVLW 0x02
    GOTO EKRANA_YAZ

TUS_3
    MOVLW 0x03
    GOTO EKRANA_YAZ

TUS_4
    MOVLW 0x04
    GOTO EKRANA_YAZ

TUS_5
    MOVLW 0x05
    GOTO EKRANA_YAZ

TUS_6
    MOVLW 0x06
    GOTO EKRANA_YAZ

TUS_7
    MOVLW 0x07
    GOTO EKRANA_YAZ

TUS_8
    MOVLW 0x08
    GOTO EKRANA_YAZ

TUS_9
    MOVLW 0x09
    GOTO EKRANA_YAZ

TUS_A
    MOVLW 0x0A
    GOTO EKRANA_YAZ

TUS_B
    MOVLW 0x0B
    GOTO EKRANA_YAZ

TUS_C
    MOVLW 0x0C
    GOTO EKRANA_YAZ

TUS_D
    MOVLW 0x0D
    GOTO EKRANA_YAZ

TUS_E
    MOVLW 0x0E
    GOTO EKRANA_YAZ

TUS_F
    MOVLW 0x0F
    GOTO EKRANA_YAZ

; ------------------------------------------------------------------------------
EKRANA_YAZ
    MOVWF PORTA

TUS_BIRAK_BEKLE
    MOVF PORTB, W
    ANDLW b'11110000'
    XORLW b'11110000'
    BTFSS STATUS, Z
    GOTO TUS_BIRAK_BEKLE

    RETURN

END