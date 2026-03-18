;***********************************************************************
; DENEY 2 - 4x4 KEYPAD: Her Tuşun Kendi Binary Değeri LED'de
;***********************************************************************
; Mikrodenetleyici : PIC16F628A
; Osilatör         : Dahili RC (INTRC), ~4MHz
;***********************************************************************
;
; KEYPAD DÜZENİ (Fiziksel tuş etiketi → Binary değer):
;
;       Sütun0  Sütun1  Sütun2  Sütun3
;        (RB0)  (RB1)   (RB2)   (RB3)
; Satır0 (RB4):  0       1       2       3
; Satır1 (RB5):  4       5       6       7
; Satır2 (RB6):  8       9       A(10)   B(11)
; Satır3 (RB7):  C(12)   D(13)   E(14)   F(15)
;
; DEĞER HESABI: değer = (satır_no × 4) + sütun_no
;
;   Örnek: '9' tuşu → Satır2, Sütun1 → (2×4)+1 = 9 → LED: 1001
;   Örnek: 'A' tuşu → Satır2, Sütun2 → (2×4)+2 = 10 → LED: 1010
;   Örnek: 'F' tuşu → Satır3, Sütun3 → (3×4)+3 = 15 → LED: 1111
;
; PORT BAĞLANTILARI:
;   PORTB RB0-RB3 → Sütunlar (ÇIKIŞ, tarama için LOW sürülür)
;   PORTB RB4-RB7 → Satırlar (GİRİŞ, 10K pull-up ile HIGH)
;   PORTA RA0-RA3 → LED D0-D3 (ÇIKIŞ, High-Aktif)
;     RA0=D0 (LSB/Bit0), RA1=D1, RA2=D2, RA3=D3 (MSB/Bit3)
;
;***********************************************************************

        LIST    P=16F628A
        #INCLUDE <P16F628A.INC>

        __CONFIG _CP_OFF & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BODEN_OFF & _LVP_OFF & _INTRC_OSC_NOCLKOUT

;***********************************************************************
; DEĞİŞKENLER
;***********************************************************************
        CBLOCK  0x20
            KEY_VAL     ; Bulunan tuşun değeri (0x00 - 0x0F)
            ROW_READ    ; Satır okuması için geçici
            COL_NUM     ; Şu an taranan sütun numarası (0-3)
            COL_MASK    ; Sütun maskesi (0x01→0x02→0x04→0x08)
            DLY_OUT     ; Gecikme dış sayacı
            DLY_IN      ; Gecikme iç sayacı
        ENDC

ROW_MASK    EQU     0xF0    ; RB4-RB7 satır bit maskesi

;***********************************************************************
; VEKTÖRLER
;***********************************************************************
        ORG     0x0000
        GOTO    INIT
        ORG     0x0004
        RETFIE

;***********************************************************************
; INIT
;***********************************************************************
INIT:
        MOVLW   0x07
        MOVWF   CMCON           ; Comparatörler KAPALI → RA0-RA3 dijital I/O

        BANKSEL TRISA
        CLRF    TRISA           ; PORTA: tümü ÇIKIŞ (LED)
        MOVLW   b'11110000'     ; RB4-RB7: GİRİŞ (Satırlar)
        MOVWF   TRISB           ; RB0-RB3: ÇIKIŞ (Sütunlar)
        MOVLW   b'01111111'     ; Bit7=0 → PORTB dahili pull-up AKTİF
        MOVWF   OPTION_REG

        BANKSEL PORTA
        CLRF    PORTA           ; Tüm LED'ler söndük
        CLRF    PORTB           ; Sütunlar LOW (taramaya hazır)

;***********************************************************************
; ANA DÖNGÜ
;***********************************************************************
MAIN_LOOP:
        CALL    GET_KEY         ; Tuş tara → KEY_VAL = 0x00..0x0F

        MOVF    KEY_VAL, W
        ANDLW   0x0F            ; Güvenli: sadece 4 bit
        MOVWF   PORTA           ; LED'lere yaz (RA3=MSB, RA0=LSB)

        CALL    WAIT_RELEASE    ; Tuş bırakılana kadar bekle

        GOTO    MAIN_LOOP

;***********************************************************************
; GET_KEY: Basılan tuşu tespit et, değerini KEY_VAL'e yaz
;
; Yöntem: Sütunları tek tek LOW sür, satırları oku.
;   LOW satır → O sütun-satır kesişimindeki tuş basılı.
;   Değer = (satır_no × 4) + sütun_no
;***********************************************************************
GET_KEY:
;------------------------------------------------------------
; ADIM 1: Herhangi bir tuşa basılana kadar bekle
;         (Tüm sütunlar LOW → herhangi bir satır LOW olursa tuş var)
;------------------------------------------------------------
WAIT_ANY:
        CLRF    PORTB           ; Tüm sütunlar LOW
        NOP
        NOP
        MOVF    PORTB, W
        ANDLW   ROW_MASK        ; Sadece satır bitleri
        XORLW   ROW_MASK        ; 0xF0 XOR 0xF0 = 0 → tuş yok (Z=1)
        BTFSC   STATUS, Z
        GOTO    WAIT_ANY        ; Tuş yok, bekle

;------------------------------------------------------------
; ADIM 2: 20ms debounce - gürültü mü gerçek mi?
;------------------------------------------------------------
        CALL    DELAY_20MS

        CLRF    PORTB           ; Tekrar tüm sütunlar LOW
        NOP
        NOP
        MOVF    PORTB, W
        ANDLW   ROW_MASK
        XORLW   ROW_MASK
        BTFSC   STATUS, Z
        GOTO    WAIT_ANY        ; Gürültüydü, başa dön

;------------------------------------------------------------
; ADIM 3: Hangi sütunda? Sütunları tek tek LOW sür
;------------------------------------------------------------
        CLRF    COL_NUM         ; Sütun sayacı = 0
        MOVLW   0x01
        MOVWF   COL_MASK        ; İlk sütun maskesi: bit0

SCAN_COL:
        ; COL_MASK'ın tersini alt 4 bite yaz:
        ;   COL_MASK=0x01 → PORTB=0x0E (RB0=0, diğerleri=1)
        ;   COL_MASK=0x02 → PORTB=0x0D (RB1=0, diğerleri=1)
        ;   COL_MASK=0x04 → PORTB=0x0B (RB2=0, diğerleri=1)
        ;   COL_MASK=0x08 → PORTB=0x07 (RB3=0, diğerleri=1)
        MOVF    COL_MASK, W
        XORLW   0xFF            ; Complement
        ANDLW   0x0F            ; Sadece alt 4 bit (üst nibble input, önemsiz)
        MOVWF   PORTB
        NOP
        NOP

        ; Bu sütunda tuş var mı?
        MOVF    PORTB, W
        ANDLW   ROW_MASK        ; Satır bitleri
        XORLW   ROW_MASK
        BTFSS   STATUS, Z       ; Z=0 → tuş var bu sütunda
        GOTO    FOUND_COL       ; Bu sütunda tuş bulundu!

        ; Bu sütunda yok → sonraki sütuna geç
        INCF    COL_NUM, F
        BCF     STATUS, C
        RLF     COL_MASK, F     ; Maskeyi sola kaydır

        MOVF    COL_NUM, W
        SUBLW   0x04
        BTFSC   STATUS, Z
        GOTO    WAIT_ANY        ; 4 sütun tarandı, bulunamadı → yeniden dene

        GOTO    SCAN_COL

;------------------------------------------------------------
; ADIM 4: Sütun bulundu. Hangi satır?
;------------------------------------------------------------
FOUND_COL:
        ; Satır pinlerini oku ve kaydet
        MOVF    PORTB, W
        ANDLW   ROW_MASK
        MOVWF   ROW_READ

        ; Satır numarasına göre temel değer belirle (satır_no × 4)
        ;   RB4=0 → Satır 0 → KEY_VAL = 0
        ;   RB5=0 → Satır 1 → KEY_VAL = 4
        ;   RB6=0 → Satır 2 → KEY_VAL = 8
        ;   RB7=0 → Satır 3 → KEY_VAL = 12

        BTFSS   ROW_READ, 4     ; RB4=0 mı? (Satır 0)
        GOTO    ROW0

        MOVLW   0x04
        MOVWF   KEY_VAL
        BTFSS   ROW_READ, 5     ; RB5=0 mı? (Satır 1)
        GOTO    ADD_COL

        MOVLW   0x08
        MOVWF   KEY_VAL
        BTFSS   ROW_READ, 6     ; RB6=0 mı? (Satır 2)
        GOTO    ADD_COL

        MOVLW   0x0C            ; RB7=0 → Satır 3
        MOVWF   KEY_VAL
        GOTO    ADD_COL

ROW0:
        CLRF    KEY_VAL         ; Satır 0 → temel değer = 0

ADD_COL:
        ; Son adım: KEY_VAL += COL_NUM
        ; Değer = (satır_no × 4) + sütun_no
        MOVF    COL_NUM, W
        ADDWF   KEY_VAL, F

        RETURN

;***********************************************************************
; WAIT_RELEASE: Tuşun bırakılmasını bekle (Debounce dahil)
;***********************************************************************
WAIT_RELEASE:
        CLRF    PORTB           ; Tüm sütunlar LOW

SCAN_REL:
        NOP
        NOP
        MOVF    PORTB, W
        ANDLW   ROW_MASK
        XORLW   ROW_MASK
        BTFSS   STATUS, Z       ; Z=1 → tüm satırlar HIGH = tuş bırakıldı
        GOTO    SCAN_REL        ; Hala basılı → bekle

        CALL    DELAY_20MS      ; Bırakış titreşimi filtrele
        RETURN

;***********************************************************************
; DELAY_20MS: ~20ms gecikme @4MHz dahili osilatör
; İç döngü: NOP(1) + DECFSZ(1/2) + GOTO(2) ≈ 4 cy × 200 = 800µs
; Dış döngü: 25 × 800µs = 20.000µs ≈ 20ms
;***********************************************************************
DELAY_20MS:
        MOVLW   .25
        MOVWF   DLY_OUT
D_OUT:
        MOVLW   .200
        MOVWF   DLY_IN
D_IN:
        NOP
        DECFSZ  DLY_IN, F
        GOTO    D_IN
        DECFSZ  DLY_OUT, F
        GOTO    D_OUT
        RETURN

;***********************************************************************
        END
;***********************************************************************
;
; TAM TUŞ TABLOSU:
;
; Tuş | Satır | Sütun | Değer | RA3 RA2 RA1 RA0
; ----+-------+-------+-------+----------------
;  0  |   0   |   0   |   0   |  0   0   0   0
;  1  |   0   |   1   |   1   |  0   0   0   1
;  2  |   0   |   2   |   2   |  0   0   1   0
;  3  |   0   |   3   |   3   |  0   0   1   1
;  4  |   1   |   0   |   4   |  0   1   0   0
;  5  |   1   |   1   |   5   |  0   1   0   1
;  6  |   1   |   2   |   6   |  0   1   1   0
;  7  |   1   |   3   |   7   |  0   1   1   1
;  8  |   2   |   0   |   8   |  1   0   0   0
;  9  |   2   |   1   |   9   |  1   0   0   1
;  A  |   2   |   2   |  10   |  1   0   1   0
;  B  |   2   |   3   |  11   |  1   0   1   1
;  C  |   3   |   0   |  12   |  1   1   0   0
;  D  |   3   |   1   |  13   |  1   1   0   1
;  E  |   3   |   2   |  14   |  1   1   1   0
;  F  |   3   |   3   |  15   |  1   1   1   1
;
;***********************************************************************
