;*******************************************************************************
; Proje Adı: 4x4 Keypad - Interrupt Tabanlı Tarama (RB Port Change)
; Yazar: Abdulkadir KELEŞ
; Denetleyici: PIC 16F628A
; Açıklama: İşlemci uyku/bekleme modundayken tuşa basıldığında kesme ile uyanır,
;           taramayı yapar ve sonucu PORTA'daki LED'lere verir.
;*******************************************************************************

    LIST P=16F628A
    INCLUDE "P16F628A.INC"

    __CONFIG _INTOSC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _LVP_OFF

;--- DEĞİŞKENLER ---
CBLOCK 0x20
    W_TEMP, STATUS_TEMP ; Kesme sırasında kaydedilecek registerlar
    D1, D2              ; Gecikme için
    TUS_KODU            ; Bulunan tuş değeri
ENDC

    ORG 0x00
    GOTO INIT

;--- KESME VEKTÖRÜ ---
    ORG 0x04
PUSH:
    MOVWF   W_TEMP          ; W ve STATUS'u yedekle (standart prosedür)
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP

ISR:
    ; Kesme RB Port Change'den mi geldi kontrol et
    BTFSS   INTCON, RBIF
    GOTO    POP
    
    CALL    DELAY_20MS      ; Debounce (Sıçrama önleme)
    
    ; --- TARAMA ALGORİTMASI ---
    ; Kesme geldiğinde hangi tuş olduğunu bulmak için kısa bir tarama yapıyoruz
    ; 1. Satırı dene
    MOVLW   B'11101111'
    MOVWF   PORTB
    BTFSS   PORTB, 0
    MOVLW   0x00            ; '0' Tuşu
    ; ... (Diğer tuş kontrol mantıkları buraya eklenir)
    ; Test amaçlı basılan satırı doğrudan PORTA'ya verelim:
    MOVWF   PORTA

    ; --- KESME HAZIRLIĞI ---
    MOVLW   B'00000000'     ; Tüm satırları tekrar "0" yap ki 
    MOVWF   PORTB           ; bir sonraki basışta kesme tetiklenebilsin.
    
    MOVF    PORTB, W        ; RBIF bayrağını temizlemek için PORTB okunmalıdır
    BCF     INTCON, RBIF    ; Bayrağı temizle

POP:
    SWAPF   STATUS_TEMP, W  ; Yedekleri geri yükle
    MOVWF   STATUS
    SWAPF   W_TEMP, F
    SWAPF   W_TEMP, W
    RETFIE

;--- GECİKME ---
DELAY_20MS:
    MOVLW D'26'
    MOVWF D1
L1: MOVLW D'250'
    MOVWF D2
L2: DECFSZ D2, F
    GOTO L2
    DECFSZ D1, F
    GOTO L1
    RETURN

;--- KURULUM ---
INIT:
    MOVLW   0x07
    MOVWF   CMCON           ; Dijital I/O modu
    
    BANKSEL TRISA
    CLRF    TRISA           ; PORTA Çıkış (LED)
    MOVLW   B'11110000'     ; RB4-RB7 Giriş (Kesme için giriş olmalı), RB0-RB3 Çıkış
    MOVWF   TRISB
    
    ; Kesme Ayarları
    BSF     INTCON, GIE     ; Global Interrupt Enable
    BSF     INTCON, RBIE    ; RB Port Change Interrupt Enable
    BCF     INTCON, RBIF    ; Bayrağı sıfırla
    
    BANKSEL PORTA
    CLRF    PORTA
    MOVLW   B'00000000'     ; Başlangıçta tüm çıkışları (satırları) 0 yap
    MOVWF   PORTB

;--- ANA DÖNGÜ ---
MAIN:
    ; İşlemci burada başka işler yapabilir veya uyuyabilir (SLEEP)
    ; Tuşa basılınca otomatik olarak ISR'ye zıplayacaktır.
    NOP
    GOTO    MAIN

    END