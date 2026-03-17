# 8-Bit CPU — Verilog Implementasyonu

Verilog ile tasarlanmış özel bir 8-bit CPU. 16-bit komut mimarisi (ISA), ileriye taşımalı (carry lookahead) ALU, 16 yazmaçlı dosya, bellek eşlemeli G/Ç ve Rust tabanlı ROM oluşturma araç zinciri içerir.

---

## Mimariye Genel Bakış

- **Veri genişliği**: 8-bit
- **Komut genişliği**: 16-bit
- **Yazmaçlar**: 16 × 8-bit genel amaçlı yazmaç (`r0`–`r15`); `r0` donanımsal sıfır yazmacıdır
- **Komut belleği**: Maksimum 2048 komut (10-bit adres, her biri 2 bayt)
- **Veri belleği**: 256 bayt (8-bit adres); 240–255 arası adresler bellek eşlemeli G/Ç'ye ayrılmıştır
- **Yığın (Stack)**: `CAL`/`RET` için donanım yığını, maksimum 16 derinlik
- **ALU bayrakları**: Sıfır (Z), Elde (C), Taşma (O), Negatif (N)
- **Yürütme modeli**: Tek döngülü (kombinasyonel veri yolu, senkron geri yazma)

---

## Komut Formatı

Tüm komutlar 16 bit genişliğindedir:

```
 15  14  13  12 | 11  10   9   8 |  7   6   5   4 |  3   2   1   0
 ───────────────┼────────────────┼────────────────┼───────────────
    Opkod (4)   |   Alan A (4)   |   Alan B (4)   |   Alan C (4)
```

Alan kullanımı komut tipine göre değişir:

**N-tipi** (`000`) — İşlenen yok
```
 15  14  13  12 | 11  10   9   8 |  7   6   5   4 |  3   2   1   0
 ───────────────┼────────────────┼────────────────┼───────────────
    Opkod (4)   |         (kullanılmaz — sıfır olmalı)
```
Komutlar: `NOP`, `HLT`, `RET`

**R-tipi** (`001`) — Yazmaçtan yazmaca işlem
```
 15  14  13  12 | 11  10   9   8 |  7   6   5   4 |  3   2   1   0
 ───────────────┼────────────────┼────────────────┼───────────────
    Opkod (4)   | Hedef yaz. (4) | Kaynak A  (4)  | Kaynak B  (4)
```
Komutlar: `ADD`, `SUB`, `NOR`, `AND`, `XOR`, `RSH`

**I-tipi** (`010`) — Anlık değer işleneni
```
 15  14  13  12 | 11  10   9   8 |  7   6   5   4 |  3   2   1   0
 ───────────────┼────────────────┼────────────────┼───────────────
    Opkod (4)   | Hedef yaz. (4) |       Anlık değer (8)
```
Komutlar: `LDI`, `ADI`

**D-tipi** (`011`) — Ofsetli bellek erişimi
```
 15  14  13  12 | 11  10   9   8 |  7   6   5   4 |  3   2   1   0
 ───────────────┼────────────────┼────────────────┼───────────────
    Opkod (4)   |  Taban yaz.(4) |  Veri yaz. (4) |   Ofset (4)
```
Komutlar: `LOD`, `STR`
- **LOD**: `Veri ← Bellek[Taban + ofset]`
- **STR**: `Bellek[Taban + ofset] ← Veri`

**A-tipi** (`100`) — Kontrol akışı / adres
```
 15  14  13  12 | 11  10   9   8 |  7   6   5   4 |  3   2   1   0
 ───────────────┼────────────────┼────────────────┼───────────────
    Opkod (4)   |  Koşul   (4)   |            Adres (8)
```
Komutlar: `JMP`, `BRH`, `CAL`
- `JMP` ve `CAL` için koşul alanı kullanılmaz
- `BRH` için koşul alanı test edilecek bayrağı seçer (örn. Z bayrağı)

---

## Komut Seti

### Temel Komutlar

| Opkod | Anımsatıcı | Açıklama | İşlenenler | Bayrak Günceller | Sözde Kod |
|-------|------------|----------|------------|------------------|-----------|
| `0000` | `NOP` | İşlem yok | — | Hayır | — |
| `0001` | `HLT` | Yürütmeyi durdur | — | Hayır | — |
| `0010` | `ADD` | Toplama | rA, rB → rC | Evet | `C ← A + B` |
| `0011` | `SUB` | Çıkarma | rA, rB → rC | Evet | `C ← A - B` |
| `0100` | `NOR` | Bit düzeyinde NOR | rA, rB → rC | Evet | `C ← !(A \| B)` |
| `0101` | `AND` | Bit düzeyinde AND | rA, rB → rC | Evet | `C ← A & B` |
| `0110` | `XOR` | Bit düzeyinde XOR | rA, rB → rC | Evet | `C ← A ^ B` |
| `0111` | `RSH` | Sağa kaydır (mantıksal) | rA → rC | Hayır | `C ← A >> 1` |
| `1000` | `LDI` | Anlık değer yükle | rA, imm8 | Hayır | `A ← imm` |
| `1001` | `ADI` | Anlık değer topla | rA, imm8 | Evet | `A ← A + imm` |
| `1010` | `JMP` | Koşulsuz atla | adres | Hayır | `PC ← adres` |
| `1011` | `BRH` | Koşullu dal | koşul, adres | Hayır | `PC ← koşul ? adres : PC+1` |
| `1100` | `CAL` | Alt program çağır | adres | Hayır | `push PC+1; PC ← adres` |
| `1101` | `RET` | Alt programdan dön | — | Hayır | `PC ← pop` |
| `1110` | `LOD` | Bellekten yükle | rA, rB, ofset | Hayır | `B ← Bellek[A + ofset]` |
| `1111` | `STR` | Belleğe depola | rA, rB, ofset | Hayır | `Bellek[A + ofset] ← B` |

<!-- ### Sahte Komutlar

Bunlar, temel komutlara dönüştürülen derleyici kolaylıklarıdır:

| Anımsatıcı | Gösterim | Açılımı | Sözde Kod |
|------------|----------|---------|-----------|
| `CMP` | `CMP A B` | `SUB A B r0` | `A - B` (bayrakları günceller) |
| `MOV` | `MOV A C` | `ADD A r0 C` | `C ← A` |
| `LSH` | `LSH A C` | `ADD A A C` | `C ← A << 1` |
| `INC` | `INC A` | `ADI A 1` | `A ← A + 1` |
| `DEC` | `DEC A` | `ADI A -1` | `A ← A - 1` |
| `NOT` | `NOT A C` | `NOR A r0 C` | `C ← !A` |
| `NEG` | `NEG A C` | `SUB r0 A C` | `C ← 0 - A` |

--- -->

<!-- ## Bellek Eşlemeli G/Ç

Veri belleğindeki 240–255 arası adresler donanım G/Ç'sine ayrılmıştır:

| Adres | O/Y | Ad | Açıklama |
|-------|-----|----|----------|
| 240 | Yaz | Piksel X | Alt 5 bit = X koordinatı |
| 241 | Yaz | Piksel Y | Alt 5 bit = Y koordinatı |
| 242 | Yaz | Piksel Çiz | (X, Y) konumuna tampon üzerinde piksel çiz |
| 243 | Yaz | Piksel Sil | (X, Y) konumundaki pikseli tampondan sil |
| 244 | Oku | Piksel Oku | (X, Y) konumundaki piksel değerini oku |
| 245 | Yaz | Ekranı Tamponla | Ekran tamponunu ekrana aktar |
| 246 | Yaz | Ekran Tamponunu Temizle | Ekran tamponunu temizle |
| 247 | Yaz | Karakter Yaz | Karakter tampon görüntüsüne karakter yaz |
| 248 | Yaz | Karakterleri Tamponla | Karakter tamponunu ekrana aktar |
| 249 | Yaz | Karakter Tamponunu Temizle | Karakter tamponunu temizle |
| 250 | Yaz | Sayı Göster | Sayı ekranında sayı göster |
| 251 | Yaz | Sayıyı Temizle | Sayı ekranını temizle |
| 252 | Yaz | İşaretli Mod | Sayıyı 2'ye tümleyen olarak yorumla `[-128, 127]` |
| 253 | Yaz | İşaretsiz Mod | Sayıyı işaretsiz olarak yorumla `[0, 255]` |
| 254 | Oku | RNG | Rastgele 8-bit sayı oku |
| 255 | Oku | Denetleyici Girişi | Denetleyici durumunu oku (Start, Select, A, B, ↑↓←→) |

**Donanım çevre birimleri:**
- 32×32 lamba ekranı
- 10 karakterlik metin ekranı
- 8-bit sayı ekranı (işaretli veya işaretsiz)
- Giriş denetleyicisi (8 düğme)
- LFSR tabanlı rastgele sayı üreteci

--- -->

## Proje Yapısı

```
.
├── src/
│   ├── cpu_core.v               # Üst düzey CPU modülü
│   ├── defines.vh               # Global sabitler ve ISA tanımları
│   ├── instruction_memory.v     # Otomatik oluşturulan ROM (elle düzenleme)
│   ├── alu/
│   │   ├── alu.v                # 8-bit ALU (8 işlem üzerinde MUX)
│   │   └── flag_generator.v     # Z, C, N, V bayrak mantığı
│   ├── control/
│   │   ├── dispatcher.v         # Kontrol birimi — tüm veri yolu sinyallerini üretir
│   │   ├── instruction_decoder.v
│   │   ├── opcode_decoder.v
│   │   └── type_decoder.v
│   ├── registers/
│   │   ├── cpu_register.v       # Parametreli D flip-flop
│   │   ├── register_file.v      # 16 × 8-bit yazmaç dosyası
│   │   └── program_counter.v    # 16-bit PC
│   ├── math_core/
│   │   ├── cla_4bit.v           # 4-bit ileriye taşımalı toplayıcı
│   │   ├── cla_8bit.v           # 8-bit CLA (iki 4-bit blok)
│   │   ├── add_sub_8bit.v       # Birleşik toplama/çıkarma birimi
│   │   └── inc_16bit.v          # PC+1 artırıcı
│   ├── logic_core/
│   │   └── bitwise_ops.v        # AND, OR, NOR, XOR, RSH
│   └── routing/
│       └── mux_8to1_8bit.v      # 8 girişli 8-bit çoklayıcı
├── tb/
│   └── cpu_core_tb.v            # Simülasyon test tezgahı
├── tools/
│   └── rom_builder/             # Rust aracı: hex → instruction_memory.v
│       └── src/
│           ├── main.rs
│           ├── lib.rs
│           ├── parser.rs        # Yorum destekli hex dosyası ayrıştırıcı
│           └── generator.rs     # Verilog case-deyimi ROM üreticisi
├── programs/
│   └── input.hex                # ROM oluşturucu için makine kodu girdisi
└── Makefile
```

---

## Derleme ve Çalıştırma

### Gereksinimler

- [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`, `vvp`)
- [GTKWave](http://gtkwave.sourceforge.net/) (isteğe bağlı, dalga formu görüntüleme için)
- [Rust](https://rustup.rs/) (ROM oluşturucu için)

### Komutlar

```bash
make all          # Tam akış: ROM oluştur → derle → simüle et
make generate_rom # programs/input.hex dosyasından instruction_memory.v oluştur
make compile      # Verilog'u iverilog ile derle
make run          # vvp ile simülasyonu çalıştır
make wave         # GTKWave'de dalga formunu aç
```

### Program Yazma

Programlar hex dosyaları olarak yazılır. Her satır bir 16-bit komuttur (en fazla 4 hex basamağı). Yorumlar (`//`) ve boş satırlar desteklenir.

```
// r1'e 5 değerini yükle
8105    // LDI r1, 5

// r2'ye 3 değerini yükle
8203    // LDI r2, 3

// r1 + r2 → r3
2123    // ADD r1 r2 r3

// Dur
1000    // HLT
```

`programs/input.hex` dosyasını `src/instruction_memory.v`'ye derlemek için `make generate_rom`, ardından simüle etmek için `make run` komutunu çalıştırın.

---

## Veri Yolu

```
         ┌─────────────┐
PC ──────►│ Komut Belleği│──► instruction[15:0]
         └─────────────┘
                │
         ┌─────────────┐
         │  Dispatcher │──► reg_we, alu_enable, alu_op,
         │  (Kontrol)  │    alu_src_b, mem_to_reg,
         └─────────────┘    pc_src, is_hlt
                │
    ┌───────────┼───────────┐
    ▼           ▼           ▼
 Yaz. Dos.    ALU        Veri Bel.
(16×8-bit)  (8-bit)    (256 bayt)
    │           │           │
    └───────────┴───────────┘
                │
           Geri Yazma
         (Yazmaç Dosyasına)
```

CPU tek döngülüdür: tüm kombinasyonel mantık bir saat periyodu içinde kararlı hale gelir; yazmaç ve bellek yazmaları yükselen kenarda gerçekleşir.

---

## Durum Bayrakları

| Bayrak | Bit | Koşul |
|--------|-----|-------|
| Z (Sıfır) | 0 | Sonuç == 0 |
| C (Elde) | 1 | İşaretsiz aritmetik taşması |
| N (Negatif) | 2 | Sonucun MSB'si == 1 |
| V (Taşma) | 3 | İşaretli aritmetik taşması |

Bayraklar yalnızca onları güncelleyen komutlar tarafından yazılır (yukarıdaki komut tablosuna bakın). Mantıksal işlemler (NOR, AND, XOR) Z, C, N, V bayraklarını günceller; RSH, LDI, JMP, BRH, CAL, RET, LOD, STR güncellemez.
