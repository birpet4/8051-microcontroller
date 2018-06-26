# 8051 mikrokontroller programozása
## Feladat megfogalmazása
Belső memóriában lévő két darab 16 bites előjeles szám osztása, 16 bites hányados és 16 bites maradék is szükséges. Bemenet: operandusok, eredmény és maradék címei (mutatók). Kimenet: eredmény, maradék.
Feladat megoldása
Programunk felépítése a következőkből áll:
1. Main – változók, bemenő paraméterek deklarálása
2. Szubrutin hívása (16 bites előjeles számok osztása) – előáll a kimenet
3. Végtelen ciklus
## Feladatunk implementálása assembly nyelven
A szubrutin (S_DIV_16) felépítése nagyvonalakban:
* osztó és osztandó előjelvizsgálata, negatív szám esetén előjel elmentése
  * SIGN_DIVIDEND, SIGN_DIVISOR
* feladat visszavezetése 16 bites előjel nélküli számok osztására
  * US_DIV_16
* eredmény korrigálása az előjelek függvényében
  * MR4R5
* visszatérés a főprogramba

*A programunkban a belső memória 0x30 – 0x31 (eredmény), 0x50-0x51 (maradék), és a SETB miatt a 0x24, az előjelvizsgálathoz, így ezeket a memóriaterületeket a rutin elején elmentjük, majd utána dolgozunk vele.*

### Előjelvizsgálat

Előjeles számokról révén szó, osztás előtt mindenképpen meg kell vizsgálnunk mind az osztandó, mind az osztó előjelét. Negatív számokat a kontroller kettes komplemensben tudja kezelni, így ebben az esetben
  * képeznünk kell a szám kettes komplemensét (bitenkénti negálás –> 1es komplemens, majd 1 hozzáadása –> 2es komplemens)
  * elmenteni az előjelét
  * és a továbbiakban ezzel a számmal dolgozni.
Az előjelvizsgálatot, majd egyben a komplemens-képzést és előjelmentést a *SIGN_DIVIDEND* és a
*SIGN_DIVISOR* nevű szubrutinok végzik.

### Feladat visszavezetése 16 bites előjel nélküli számok osztására

Mivel az egyes aritmetikai műveletek végrehajtásához kizárólag 8 bites regiszterek állnak a
rendelkezésünkre (kiv. DPTR), így a DIV operátor nem használható 16 bites számok osztására. Az elv
teljesen analóg az írásbeli 10-es számrendszerbeli osztáshoz, megvalósítása binárisan, assembly
nyelven *(US_DIV_16)*:
* Start
  * Ismétlés
    * Kivonjuk egymásból az osztandó legfelső éppen shiftelt bitjét és az osztót
      * Tulajdonképpen ez egy komparálás, megnézzük, hogy mikor lesz az
osztandó >=, mint az osztó (figyeljük a carry-t)
    * Ha az aktuális osztandó >= osztó
      * A kvóciensbe 1-et mozgatunk
    * Egyébként 0-t
  * Ciklusszámláló != 0 (16)
* STOP

### Eredmény korrigálása az előjelek függvényében

Miután elvégeztük az osztást, megvizsgáljuk, hogy eredetileg milyen előjelű volt az osztó és az
osztandó. Ha mindkettő pozitív vagy negatív volt, nincsen dolgunk, máskülönben vennünk kell az
eredmény kettes komplemensét, és visszaírni az eredményregiszterbe. *(MR4R5)*
