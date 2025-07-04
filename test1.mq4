//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
//EA Utama

//+------------------------------------------------------------------+
//| SISTEM PERLINDUNGAN LISENSI (EA UTAMA)                          |
//| Fungsi: Mengawal akses EA berdasarkan kunci lesen yang sah       |
//+------------------------------------------------------------------+

#property strict

// Jenis tempoh lesen
enum TIME_UNIT
  {
   UNIT_DAYS,    // Hari
   UNIT_MONTHS,  // Bulan
   UNIT_YEARS    // Tahun
  };

// Tetapan pengguna boleh ubah
input string LicenseKey = "";           // Masukkan kunci lesen
input int    ValidDuration = 1;         // Tempoh sah lesen
input TIME_UNIT TimeUnit = UNIT_MONTHS; // Unit masa (Hari/Bulan/Tahun)

// Kunci pentadbiran (hanya untuk pembangun)
const string ADMIN_KEY = "ADMIN MODE XYZ";

// Pemboleh ubah global
datetime ExpiryDate; // Tarikh tamat lesen

//+------------------------------------------------------------------+
//| Fungsi utama EA                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
// Semak lesen semasa EA dimulakan
   if(!ValidateLicense())
     {
      Alert("EA TIDAK DAPAT DIGUNAKAN: Kunci lesen tidak sah/telah tamat!");
      return(INIT_FAILED);
     }

// Papar maklumat lesen pada carta
   Comment("Lesen untuk Akaun #", AccountNumber(),
           "\nSah sehingga: ", TimeToString(ExpiryDate, TIME_DATE));
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Fungsi pengesahan lesen (STRICT VALIDATION)                      |
//+------------------------------------------------------------------+
bool ValidateLicense()
  {
// 1. Semak jika kunci lesen kosong
   if(StringLen(LicenseKey) == 0)
     {
      Alert("RALAT: Tiada kunci lesen dimasukkan");
      return false;
     }

// 2. Mod pentadbiran (hanya untuk akaun demo)
   if(LicenseKey == ADMIN_KEY)
     {
      if(!IsDemo())
        {
         Alert("MOD ADMIN hanya untuk akaun demo");
         return false;
        }
      ExpiryDate = D'31.12.2099'; // Lesen kekal
      Print("MOD ADMIN: Akses pembangun diaktifkan");
      return true;
     }

// 3. Semak format kunci (XXXX-XXXX-XXXX-XXXX)
   if(StringLen(LicenseKey) != 19 || StringFind(LicenseKey, "-") != 4)
     {
      Alert("RALAT: Format kunci tidak sah");
      return false;
     }

// 4. Ekstrak bahagian kunci
   string parts[4];
   for(int i = 0; i < 4; i++)
     {
      parts[i] = StringSubstr(LicenseKey, i * 5, 4);
      if(StringLen(parts[i]) != 4)
        {
         Alert("RALAT: Struktur kunci rosak");
         return false;
        }
     }

// 5. Bina semula hash kunci
   int keyHash = 0;
   for(int i = 0; i < 4; i++)
     {
      keyHash |= (int)StringToInteger(parts[i]) << (i * 4);
     }

// 6. Semak kesesuaian akaun
   int keyAccount = keyHash & 0xFFFF;
   if(keyAccount != 0 && keyAccount != AccountNumber())
     {
      Alert("RALAT: Lesen tidak untuk akaun ini");
      return false;
     }

// 7. Semak tempoh lesen
   int daysValid = (keyHash >> 16) & 0xFFFF;
   ExpiryDate = TimeCurrent() + daysValid * 86400;
   if(TimeCurrent() > ExpiryDate)
     {
      Alert("RALAT: Lesen telah tamat pada ", TimeToString(ExpiryDate, TIME_DATE));
      return false;
     }

// 8. Pengesahan akhir (bandingkan dengan kunci yang dijana semula)
   string expectedKey = GenerateLicenseKey(keyAccount, ExpiryDate);
   if(expectedKey != LicenseKey)
     {
      Alert("RALAT: Kunci lesen tidak sah");
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Fungsi menjana kunci lesen                                       |
//+------------------------------------------------------------------+
string GenerateLicenseKey(int accountNumber, datetime expiryDate)
  {
   int daysValid = (int)((expiryDate - TimeCurrent()) / 86400);
//+------------------------------------------------------------------+
   daysValid = MathMin(daysValid, 65535); // Had maksimum 179 tahun

   int combinedHash = (daysValid << 16) | (accountNumber & 0xFFFF);

   string key = "";
   for(int i = 0; i < 4; i++)
     {
      key += StringFormat("%04X", (combinedHash >> (i * 4)) & 0xFFFF);
      if(i < 3)
         key += "-";
     }
   return key;
  }

//+------------------------------------------------------------------+
//| Fungsi tamat EA                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) { Comment(""); }
