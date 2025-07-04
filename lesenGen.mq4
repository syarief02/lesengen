//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
//lesen Generator

//+------------------------------------------------------------------+
//| PENJANA KUNCI LISENSI                                            |
//| Fungsi: Mencipta kunci lesen untuk EA Utama                      |
//+------------------------------------------------------------------+

#property strict

// Jenis tempoh lesen
enum TIME_UNIT
  {
   UNIT_DAYS,
   UNIT_MONTHS,
   UNIT_YEARS
  };

// Tetapan yang boleh diubah oleh pengguna
input int    AccountNumber = 0;         // 0 untuk demo, nombor akaun untuk lesen sebenar
input int    ValidDuration = 1;         // Tempoh sah lesen
input TIME_UNIT TimeUnit = UNIT_MONTHS; // Unit masa
input bool   ForDemoAccount = false;    // Cipta lesen demo?

//+------------------------------------------------------------------+
//| Fungsi utama penjana                                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   int targetAccount = ForDemoAccount ? 0 : AccountNumber;
   string accType = (targetAccount == 0) ? "Akaun Demo" : "Akaun Sebenar";

// Kira tarikh tamat lesen
   datetime expiryDate = CalculateExpiryDate(TimeCurrent(), ValidDuration, TimeUnit);

// Jana kunci lesen
   string licenseKey = GenerateLicenseKey(targetAccount, expiryDate);
Print(targetAccount);
// Papar maklumat dalam log
   string unitStr = (TimeUnit == UNIT_DAYS) ? "Hari" :
                    (TimeUnit == UNIT_MONTHS) ? "Bulan" : "Tahun";

   Print("=== KUNCI LISENSI DICIPTA ===");
   Print("Jenis Akaun: ", accType);
   Print("Nombor Akaun: ", (targetAccount > 0 ? IntegerToString(targetAccount) : "(Mana-mana)"));
   Print("Tempoh Sah: ", ValidDuration, " ", unitStr);
   Print("Tarikh Tamat: ", TimeToString(expiryDate, TIME_DATE));
   Print("Kunci Lesen: ", licenseKey);

// Tunjukkan popup
   MessageBox(
      "✅ KUNCI LISENSI BERJAYA DICIPTA\n\n" +
      "Jenis Akaun: " + accType + "\n" +
      (targetAccount > 0 ? "Nombor Akaun: " + IntegerToString(targetAccount) + "\n" : "") +
      "Tempoh Sah: " + IntegerToString(ValidDuration) + " " + unitStr + "\n" +
      "Tarikh Tamat: " + TimeToString(expiryDate, TIME_DATE) + "\n\n" +
      "KUNCI LISENSI:\n" + licenseKey +
      "\n\nSalin kunci ini ke EA Utama anda",
      "PENJANA LISENSI REDTIEMANAGER",
      0
   );

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Fungsi kira tarikh tamat lesen                                   |
//+------------------------------------------------------------------+
datetime CalculateExpiryDate(datetime startDate, int duration, TIME_UNIT unit)
  {
   MqlDateTime mqlDate;
   TimeToStruct(startDate, mqlDate);

   switch(unit)
     {
      case UNIT_DAYS:
         return startDate + duration * 86400;

      case UNIT_MONTHS:
         mqlDate.mon += duration;
         if(mqlDate.mon > 12)
           {
            mqlDate.year += mqlDate.mon / 12;
            mqlDate.mon = mqlDate.mon % 12;
           }
         return StructToTime(mqlDate);

      case UNIT_YEARS:
         mqlDate.year += duration;
         return StructToTime(mqlDate);
     }

   return startDate;
  }

//+------------------------------------------------------------------+
//| Fungsi menjana kunci lesen (sama dengan EA Utama)                |
//+------------------------------------------------------------------+
string GenerateLicenseKey(int accountNumber, datetime expiryDate)
  {
   int daysValid = (int)((expiryDate - TimeCurrent()) / 86400);
   daysValid = MathMin(daysValid, 65535);

   int combinedHash = (daysValid << 16) | (accountNumber & 0xFFFF);

   string key = "";
   for(int i = 0; i < 4; i++)
     {
      key += StringFormat("%04X", (combinedHash >> (i * 4)) & 0xFFFF);
      if(i < 3)
         key += "-";
     }
     Print(expiryDate);
   return key;
  }
//+------------------------------------------------------------------+
