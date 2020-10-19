;---------------------------------------------------------------------------------------------------------
; Program przelicza wspolrzedne bryly wokol trzech osi (x,y,z).
; Idea samego efektu zaciagnieta z ksiazki G.Michalka 'Co i jak w assemblerze'
; Procedury przeliczajace wspolrzedne punktow + perspektywe z wykorzystaniem
; jednostki zmiennoprzecinkowej (FPU):
; Jacek 'Quasar' Pietruszka 1999.09.18.
; 
; Modyfikacje:
; Zmiana bryly na US SOSNOWIEC + dodanie efektu ognia + scroll + inne:
; Jacek 'Quasar' Pietruszka - 2005.06.12.
; 
; Kontakt: 
; pietruszka.jacek@gmail.com
;
;---------------------------------------------------------------------------------------------------------

MODEL small
STACK 512h
.386

Bufor_Video SEGMENT
buf_video db 320*200 dup(?) ;bufor ekranu
Bufor_Video ENDS

.data

include paleta.pal   ;paleta kolorow
include punkty.inc   ;wspolrzedne punktow
include laczenia.inc ;polaczenia poszcz. punktow (linie)
include fonty.inc    ;fonty 8x8 (640x8)

;                U  S  '  s  o  s  n  o  w  i  e  c
ile_punktow equ 20+44+08+40+24+40+22+24+24+24+24+32 ;liczba punktow
ile_linii   equ 30+66+12+60+36+60+33+36+36+36+36+48 ;liczba linii

;wspolrzedne linii
x1         dw  0    ;Wspolrzedna X poczatku linii
y1         dw  0    ;Wspolrzedna Y poczatku linii
x2         dw  0    ;Wspolrzedna X konca linii
y2         dw  0    ;Wspolrzedna Y konca linii
line_color db  090h ;Kolor linii

;kolor tla
tlo_color db 00h

;zmienne korygujace
kor_x dw 150
kor_y dw 100

;perspektywa
zv	dw -180   ;wspolrzedna oka
zv1	dd -25600 ;natezenie perspektywy (zv*256)

;wspolrzedne punktu obrotu
;x0	dw 0
;y0	dw 0
;z0	dw 0

;katy
kat_x dw 0
;kat_y dw 0
;kat_z dw 0

;zmienne pomocnicze
_180 dw 180
_256 dw 256

;tablice
ekran dw ile_punktow dup(0,0)   ;tablica po wszystkich przeliczeniach
root  dw ile_punktow dup(0,0,0) ;tablica na wspolrzedne

credits db "Code, calculated by Jacek 'Quasar' Pietruszka",13,10
        db "Idea from 'CO I JAK W ASSEMBLERZE' by Grzegorz Michalek",13,10,13,10,'$'

;zmienne generatora liczb losowych
Seed     dw 1111h ;Zmienna pomocnicza do generatora liczb losowych
RndHi    dw 0     ;Gorny zakres generowanych liczb
RndLo    dw 0     ;Dolny zakres generowanych liczb
rand_col db 0

;zmienne scroll'a
;tekst      db "Dostepne znaki: 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@$()-+;:'.,? "
tekst      db "Witam! Nie bardzo wiem co pisac w tym scrollu. Moze cos na temat tego lamerskiego intra ;-). "
           db "Logo sklada sie z 325 punktow, ktore sa polaczone 489 liniami (jak dobrze policzylem ;-)). " 
           db "Punkty liczone sa w czasie rzeczywistym, przez jednostke zmiennoprzecinkowa procesora (FPU). "
           db "Efekt ognia oraz proporcjonalny scroll (nie wiem czy takie pojecie wystepuje na PC) chyba nie "
           db "wymagaja komentarza. "
           db "Teraz kredyty... Idea + pewne rozwiazania obracajacej sie bryly: Grzegorz Michalek. "
           db "Kod (procedury obrotow punktow liczone przez FPU wokol trzech osi + wszelkie kalkulacje + budowa bryly + "
           db "efekt ognia nalozony na napis + scroll + grafika oraz cala reszta: "
           db "Jacek 'Quasar' Pietruszka. Fonty pochodza z Commodore C64. Paleta kolorow (cialo czarne) z Adobe Photoshop v5.0. "
           db "Calosc zostala skompilowana w Turbo Assemblerze v3.1, tekst zrodlowy wpisalem w Chrome v1.22 Integrated "
           db "Development Environment by Franck Charlet. "
           db "Sterowanie: '+', '-' intensywnosc plomienia, 'spacja' obrot w kierunku przeciwnym... "
           db "Pozdrowienia dla Hortex'a, Zaby (Moog'a), Romana oraz reszty, o ktorych zapomnialem ;-) "                                         
           db "(sorki). Pozdrowienia rowniez dla calej sceny C64. Esc: wyjscie.                                                  "
           db "                                          "
           db 0ffh
           ;   0  1  2  3  4  5  6  7  8  9 10 11 12 13 cd bin
           14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 
przemapow  db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
           ;  32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 
           ;      !        $        '  (  )     +  ,  -  .     0  1  2  3  4  5  6  7  8  9  :  ;           ?
           db 00,33,00,00,35,00,00,37,37,37,00,38,38,38,38,00,39,39,39,39,39,39,39,39,39,39,39,39,00,00,00,42
           ;  64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95
           ;   @  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z  
           db 42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,00,00,00,00,00
           ;  96 97 98 99 ...
           ;      a  b  c  d  e  f  g  h  i  j  k  l  m  n  o  p  q  r  s  t  u  v  w  x  y  z
           db 00,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48,48
wsk_tekstu dw 0
poz_fonta  db 0
spacja     equ 3
scroll_y   equ 180
lwait      dw 5

                
.code
main:
	mov  ax,@data
	mov  ds,ax
	finit              ;inicjalizacja fpu
	mov ax,0013h       ;init trybu
	int 10h            ;320x200x256
	call set_keyboard  ;ustawia tryb pracy klawiatury (czestotliwosc powtarzania itp.)
	call przelicz_lacz ;przelicz laczniki
	call paleta        ;ustaw palete kolorow
	call clear_bufor
@mainloop:
	call clr_bfr_keyb  ;czysc bufor klawiatury
	call copy_root     ;kopiuj wspolrz. do tab. roboczej
	;call clear_bufor  ;czysc bufor ekranu
	call rad_sin_cos   ;policz sin i cos danego kata (rad)
	call root_z        ;obroc wokol x
	call root_y        ;obroc wokol y
	call root_x        ;obroc wokol x
	
	call perspective   ;przelicz na wspolrzedne ekranowe (perspektywa)
	call draw_bufor    ;rysuj do bufora
	call ogien         ;efekt ognia
	call scroll
	call no_vret       ;czekaj na powrot pionowy
	call draw_0A000h   ;kopiuj z bufora na ekran
	;call no_vret      ;czekaj na powrot pionowy
dalej:
	in   al,60h        ;czytaj port klawiatury
	cmp  al,57         ;spr czy spacja
	jne  incuj_kat     ;jesli tak to
	dec  kat_x         ;zmniejsz kat
	cmp  kat_x,0       ;spr czy nastapi obrot o 360 stopni
	jnz  @plus	   ;jesli nie to sprawdz klawisz
	mov  kat_x,360	   ;jesli tak to ustaw kat na 360 (reset)
	jmp  @plus
incuj_kat:
	inc  kat_x
	cmp  kat_x,360	   ;spr czy nastapi obrot o 360 stopni
	jnz  @plus         ;jesli nie to sprawdz klawisz
	mov  kat_x,0       ;jesli tak to ustaw kat 0 (reset)
@plus:
	cmp al,4eh         ;sprawdz grey '+'
	jne @minus         ;jesli nie to spr. grey '-'
	cmp line_color,255 ;maxymalna wielkosc bryly
	je  @minus
	add line_color,1
@minus:
	cmp  al,4ah        ;sprawdz grey '-'
	jne @esc           ;jesli nie to spr. czy esc
	cmp line_color,0   ;minimalna wielkosc bryly
	je  @esc			        
	sub line_color,1
@esc:
	cmp  al,01h	   ;czy nacisniety klawisz ESC
	jne  @mainloop     ;petla i nastepny cykl
	mov  ax,03h        ;powrot do trybu teksowego
	int  10h	   ;tryb tekstowy 03h
	call clr_bfr_keyb  ;czyszczenie bufora klawiatury
	call display_txt   ;creditsy
	mov  ax,4c00h	   ;powrot do wiersza polecen DOS
	int  21h	   ;

;-------------------------------------------------------------------------------------------------
; procedura czysci bufor ekranu
;-------------------------------------------------------------------------------------------------
clear_bufor PROC
	mov ax,Bufor_Video 
	mov es,ax
	mov di,0
	mov al,tlo_color
	mov ah,al
	mov cx,320*200/2    ;32000 ;(32000*2 = 64000 = 320*200)
	rep stosw
	ret
	ENDP
;-------------------------------------------------------------------------------------------------
; procedura zmienia parametry pracy klawiatury
;-------------------------------------------------------------------------------------------------
set_keyboard PROC
	mov ax,0305h
	mov bx,00h
	int 16h
	ret
	ENDP
;-------------------------------------------------------------------------------------------------
; procedura czysci bufor klawiatury
;-------------------------------------------------------------------------------------------------
clr_bfr_keyb PROC
	mov ah,0ch
	int 21h
	ret
	ENDP
;-------------------------------------------------------------------------------------------------
; procedura kopiuje z bufora na ekran
;-------------------------------------------------------------------------------------------------
draw_0A000h PROC
	push ds
	push es
	mov ax,0a000h
	mov es,ax
	mov ax,Bufor_Video
	mov ds,ax
	mov di,0
	mov si,0
	mov cx,16000
	rep movsd
	pop es
	pop ds
	ret
	ENDP
;-------------------------------------------------------------------------------------------------
; procedura kopiuje tablice wspolrzednych do tablicy roboczej root
;-------------------------------------------------------------------------------------------------
copy_root PROC
	mov  si,offset logo
	mov  di,offset root
	push ds
	pop  es
	mov  cx,ile_punktow*3 ;kazdy punkt opisany jest przy pomocy 3 wspolrzednych x,y,z
	rep  movsw            ;kazdy punkt to 2 bajty typ word
	ret			
	ENDP
;-------------------------------------------------------------------------------------------------
; procedura czeka na powrot pionowy (No VRET...)
;-------------------------------------------------------------------------------------------------
no_vret PROC
	mov  dx,3dah   
wai:
	in   al,dx
	test al,8
	je   wai
wai1:
	in   al,dx
	test al,8
	jne  wai1
	ret
	ENDP
;-------------------------------------------------------------------------------------------------
; procedura przelicza stopnie na radiany oraz liczy sin i cos danego kata
;-------------------------------------------------------------------------------------------------
rad_sin_cos PROC
	fild  word ptr kat_x ;laduj do st(0) kat     			                0
	fldpi		     ;laduj PI               			                0 1
	fild word ptr _180   ;laduj 180              			                0 1 2
	fdivp		     ;zamien st(1) z st(1)/st(0) i zdejmij z wiezcholka 0 1
	fmulp                ;mnoz i zdejmij					        0
	fsincos              ;liczy sin i cos				                0 1
	ret
	ENDP
;--------------------------------------------------------------------------------------------------
; procedura obraca wokol osi Z
;
; Xo, Yo - wspolrzedne punktu obrotu
; X, Y   - wspolrzedne obracanego punktu
; a	 - kat o jaki obracamy
; Xr, Yr - wspolrzedne punktu po obrocie
;
; Xr=Xo+(X-Xo)*cosa+(Y-Yo)*sina
; Yr=Yo+(Y-Yo)*cosa-(X-Xo)*sina
;
; Xo=0, Yo=0 => Xr=X*cosa+Y*sina
;		Yr=Y*cosa-X*sina
;-------------------------------------------------------------------------------------------------
root_z PROC
	lea   si,root         ;offset tab. z punktami zrodlowymi
	lea   di,root         ;offset tab. na punkty po przeliczeniach (ta sama tablica)
	mov   cx,ile_punktow
next_point_z:
	fild  word ptr [si]   ;laduj X
	fild  word ptr [si+2] ;laduj Y
	;----------------
	; X*cosa + Y*sina
	;----------------
	fld   st(1)           ;laduj X na wierzcholek stosu
	fmul  st,st(3)        ;X*cosa
	fld   st(1)           ;laduj Y na wierzcholek stosu
	fmul  st,st(5)        ;(Y*sina)
	faddp st(1),st        ;(Y*sina)+(X*cosa)
	fistp word ptr [di]   ;zapisz do tab. pomocniczej i zdejmij ze stosu
	;----------------
	; Y*cosa - X*sina
	;----------------
	fmul  st,st(2)        ;Y jest w st... (Y*cosa)
	fxch                  ;(Y*cosa) <-> X
	fmul  st,st(3)        ;(X*sina)
	fsubp st(1),st        ;(Y*cosa)-(X*sina)
	fistp word ptr [di+2] ;zapisz do tab. pomocniczej i zdejmij ze stosu
	add   di,6            ;nastepny punkt w tab. zrodlowej
	add   si,6            ;nastepny punkt w tab. docelowej
	loop  next_point_z    ;loop...
	ret
	ENDP
;--------------------------------------------------------------------------------------------------
; procedura obraca wokol osi Y
;
; Xo, Zo - wspolrzedne punktu obrotu
; X, Z   - wspolrzedne obracanego punktu
; a	 - kat o jaki obracamy
; Xr, Zr - wspolrzedne punktu po obrocie
;
; Xr=Xo+(X-Xo)*cosa-(Z-Zo)*sina
; Zr=Zo+(Z-Zo)*cosa+(X-Xo)*sina
;
; Xo=0, Zo=0 => Xr=X*cosa-Z*sina
; Zr=Z*cosa+X*sina
;-------------------------------------------------------------------------------------------------
root_y PROC
	lea   si,root         ;offset tab. z punktami zrodlowymi
	lea   di,root         ;offset tab. na punkty po przeliczeniach (ta sama tablica)
	mov   cx,ile_punktow
next_point_y:
	fild  word ptr [si+4] ;laduj Z
	fild  word ptr [si]   ;laduj X
	;----------------
	; X*sina - Z*cosa
	;----------------
	fld   st(1)           ;laduj Z
	fmul  st,st(3)        ;Z*cosa
	fld   st(1)           ;laduj X
	fmul  st,st(5)        ;(X*sina)
	fsubp st(1),st        ;(X*sina)-(Z*cosa)
	fistp word ptr [di+4] ;zapisz do tab. pomocniczej i zdejmij ze stosu
	;----------------
	; X*cosa + Z*sina
	;----------------
	fmul  st,st(2)        ;X jest w st... (X*cosa)
	fxch                  ;(X*cosa) <-> Z
	fmul  st,st(3)        ;(Z*sina)
	faddp st(1),st        ;(X*cosa)+(Z*sina)
	fistp word ptr [di]   ;zapisz do tab. pomocniczej i zdejmij ze stosu
	add   di,6            ;nastepny punkt w tab. zrodlowej
	add   si,6            ;nastepny punkt w tab. docelowej
	loop  next_point_y    ;loop...
	ret
	ENDP
;--------------------------------------------------------------------------------------------------
; procedura obraca wokol osi X
;
; Yo, Zo - wspolrzedne punktu obrotu
; Y, Z   - wspolrzedne obracanego punktu
; a	 - kat o jaki obracamy
; Yr, Zr - wspolrzedne punktu po obrocie
;
; Yr=Yo+(Y-Yo)*cosa+(Z-Zo)*sina
; Zr=Zo+(Z-Zo)*cosa-(Y-Yo)*sina
;
; Yo=0, Zo=0 => Yr=Y*cosa+Z*sina
;		Zr=Z*cosa-Y*sina
;-------------------------------------------------------------------------------------------------
root_x PROC
	lea   si,root	      ;offset tab. z punktami zrodlowymi
	lea   di,root         ;offset tab. na punkty po przeliczeniach (ta sama tablica)
	mov   cx,ile_punktow
next_point_x:
	fild  word ptr [si+2] ;laduj Y
	fild  word ptr [si+4] ;laduj Z
	;----------------
	; Y*cosa + Z*sina
	;----------------
	fld   st(1)           ;laduj Y
	fmul  st,st(3)        ;Y*cosa
	fld   st(1)           ;laduj Z
	fmul  st,st(5)        ;(Z*sina)
	faddp st(1),st        ;(Z*sina)+(Y*cosa)
	fistp word ptr [di+2] ;zapisz do tab. pomocniczej i zdejmij ze stosu
	;----------------
	; Z*cosa - Y*sina
	;----------------
	fmul  st,st(2)        ;Z jest w st... (Z*cosa)
	fxch                  ;(Z*cosa) <-> Y
	fmul  st,st(3)        ;(Y*sina)
	fsubp st(1),st        ;(Z*cosa)-(Y*sina)
	fistp word ptr [di+4] ;zapisz do tab. pomocniczej i zdejmij ze stosu
	add   di,6            ;next point w tab. source
	add   si,6            ;next point w tab. destination
	loop  next_point_x    ;loop...
	ret
	ENDP
;-------------------------------------------------------------------------------------------------
; procedura przelicza perspektywe
;
; xp=-x*zv1/(z-zv)/256
; yp=-y*zv1/(z-zv)/256
;-------------------------------------------------------------------------------------------------
perspective PROC
	finit                     ;czysc stos
	lea   si,root             ;laduj offset do si
	lea   di,ekran            ;laduj offset do di
	mov   cx,ile_punktow      ;
	fild  dword ptr zv1       ;laduj zv1
	fild  word ptr zv         ;laduj zv
next_r:
	fild  word ptr [si]       ;laduj X
	fchs                      ;zmien znak
	fild  word ptr [si+2]     ;laduj y
	;fchs                     ;zmien znak
	fild  word ptr [si+4]     ;laduj z
	fsub  st,st(3)            ;z-zv
	fdivr st,st(4)            ;zv1/(z-zv) -> st
	fmul  st(2),st            ;-x*zv1/(z-zv)
	fmulp st(1),st            ;-y*zv1/(z-zv) i zdejmij zv1/(z-zv) z st
	fistp word ptr [di+2]     ;zapisz w tab. ekran y
	fistp word ptr [di]       ;zapisz w tab. ekran x
	sar   word ptr [di],8     ;podziel przez 256 x
	sar   word ptr [di+2],8   ;podziel przez 256 y
	add   word ptr [di],  160 ;
	add   word ptr [di+2],100 ;zmienne korygujace
	add   di,4                ;next point w tab. destination
	add   si,6                ;next point w tab. source
	loop  next_r
	ret
	ENDP
;-------------------------------------------------------------------------------------------------
; procedura rysuje poszczegolne linie w buforze video
;-------------------------------------------------------------------------------------------------
draw_bufor PROC
	push ds
	pop  es
	lea di,tab_lacz
	lea si,ekran
	mov cx,ile_linii
rysuj:
	mov bx,es:[di]	    ;laduj pierwszy lacznik
	mov bp,es:[di+2]    ;laduj drugi lacznik
	mov ax,ds:[si+bx]   ;laduj x1 do ax
	mov dx,ds:[si+bx+2] ;laduj y1 do dx
	mov x1,ax           ;zapisz x1
	mov y1,dx           ;zapisz y1
	mov ax,ds:[si+bp]   ;laduj x2 do ax
	mov dx,ds:[si+bp+2] ;laduj y2 do dx
	mov x2,ax           ;zapisz x2
	mov y2,dx           ;zapisz y2
	push si             ;si na stos
	push di             ;di na stos
	push cx             ;cx na stos
	call line           ;rysuj linie
	pop cx              ;pobierz ze stosu cx
	pop di              ;pobierz ze stosu di
	pop si              ;pobierz ze stosu si
	add di,4            ;przeskocz na nastepny lacznik
	loop rysuj          ;loop...
	ret
	ENDP
;-------------------------------------------------------------------------------------------------
; przelicza kazdy punkt (lacznikowy) na odpowiedni offset (*4)
;-------------------------------------------------------------------------------------------------
przelicz_lacz PROC
	push ds
	pop es
	mov di,offset tab_lacz
	mov cx,ile_linii
	shl cx,1
next_wsp:
	mov ax,es:[di]   	 ;es, ds to "samo"
	shl ax,1
	shl ax,1
	stosw
	loop next_wsp
	ret
	ENDP
;------------------------------------------------------------------------------
; procedura wyswietla creditsy
;------------------------------------------------------------------------------
display_txt:
	mov dl,0              ;
	mov dh,0              ;
	mov ah,02h            ;
	mov bh,0              ;ustaw kursor 0,0
	int 10h               ;
	mov dl,0
	mov dh,0
	mov dx,offset credits
	mov ah,09h
	int 21h
	ret
	ENDP
;------------------------------------------------------------------------------
; procedura ustawia palete kolorow
;------------------------------------------------------------------------------
paleta PROC
	mov cl,0
	mov bx, offset PaletaKolorow
ustaw:
	mov dx,03c8h                  ;nr koloru ktory bedziemy ustawiac do 03c8h
	mov al,cl
	out dx,al                     ;zapis nr koloru ktory ustawiac bedziemy
	inc dx                        ;do 03c9h po kolei r g b
	mov al,[bx]                   ;pobierz r
	shr al,2
	out dx,al                     ;r -> 03c9h
	mov al,[bx+1]                 ;pobierz g
	shr al,2
	out dx,al                     ;g -> 03c9h
	mov al,[bx+2]                 ;pobierz b
	shr al,2
	out dx,al                     ;b -> 03c9h
	add bx,03h
	inc cl
	;cmp cl,0
	jne ustaw
	ret
	ENDP
;------------------------------------------------------------------------------
; procedura efekt ognia
;
; for Y := 1 to WysokoscEkranu do
; begin
;   Kolor := PobierzKolor(X, Y);
;   if Kolor(X, Y) > 10 then
;   begin
;     PostawPunkt(X, Y, 0);
;     PostawPunkt(X, Y-1, Kolor-Random(10));
;   end
; else PostawPunkt(X, Y-1, 0)
; end;
;------------------------------------------------------------------------------
ogien PROC
	mov bx,Bufor_Video
	mov es,bx
	mov byte ptr RndHi,10      ;gorny zakres losowanych liczb
	mov byte ptr RndLo,0       ;dolny zakres losowanych liczb
	mov cx,0
	mov bx,320                 ;Y=1
@loop0:
	mov cl,es:[bx]             ;laduj kolor do dl (Kolor := PobierzKolor(X, Y))
	cmp cl,10                  ;if kolor > 10 then ... to dalej
	jb  @else1                 ;< 10 else skok do @else1
	call random                ;generuj losowa wartosc
	
	sub cl,rand_col	           ;Kolor-Random(10)
	mov es:[bx-320],cl         ;PostawPunkt(X, Y-1, Kolor-Random(10))
	jmp @loop1
@else1:
	mov byte ptr es:[bx-320],0 ;else PostawPunkt(X, Y-1, 0)
@loop1:
	inc bx                     ;kolejny piksel
	cmp bx,320*179             ;czy koniec
	jne @loop0                 ;jak nie to dalej
	ENDP
;------------------------------------------------------------------------------
; procedura generuje liczbe losowa z zakresu od Rndlo do Rndhi
;------------------------------------------------------------------------------
random PROC
   	push bx
   	mov  bx,Seed
   	add  bx,9248h
   	ror  bx,1
   	ror  bx,1
   	ror  bx,1
   	mov  Seed,bx
   	mov  ax,Rndhi
   	sub  ax,Rndlo
   	mul  bx
   	mov  ax,dx
   	add  ax,Rndlo
   	pop  bx
   	mov  byte ptr rand_col,al
   	ret
   	ENDP
;------------------------------------------------------------------------------
; procedura $D016, scroll tekstu
;------------------------------------------------------------------------------
scroll PROC
        ;dec lwait
	;jnz @scexit
	;mov lwait,1
	                
        push ds                 ;seg. danych na stos
        mov ax,seg Bufor_Video  ;adres seg bufora do ax
	mov es,ax               ;es wsk. na bufor
	mov ds,ax               ;ds wsk. na bufor
	mov si,320*scroll_y+1   ;wsk. na drugi piksel w linii (docelowy)
        mov di,320*scroll_y     ;wsk. na pierwszy piksel w linii (zrodlowy)
        mov al,8                ;ile linii do rollowania
@rollx8:
        mov cx,319              ;dlugosc linii w pikselach, bez pierwszego
        rep movsb               ;rolluj jedna linie, pierwszy pixel jest nadpisywany drugim, drugi trzecim itd.
        add di,1                ;przejscie do nastepnej linii (cel)
        add si,1                ;przejscie do nastepnej linii (zrodlo)
        dec al                  ;zmniejsz licznik linii
        jnz @rollx8             ;rolluj kolejna linie 
        pop ds                  ;przywroc seg. danych ze stosu
@pobierz_litere:
        mov bx,offset tekst     ;adres pierwszego znaku tekstu
        mov si,wsk_tekstu       ;nr litery 
        mov byte ptr al,[bx+si] ;pobierz litere
                       
        cmp al,0ffh             ;czy to koniec tekstu
        jne @nie_ost_znak       ;jak nie to skocz do etykiety nie_ost_znak
        mov wsk_tekstu,0        ;jak tak to zeruj wsk tekstu, wskazuje teraz na pierwsza litere tekstu
        jmp @pobierz_litere     ;i pobierz ten znak
@nie_ost_znak:        	                
        cmp al,' '              ;czy to spacja
        jne @nie_spacja         ;jak nie to skocz do przemapowywania ascii na moj format fontow
        cmp poz_fonta,spacja    ;jesli tak to spr. czy zostala cala wyrysowana
        jne @spacja             ;jesli nie to dalej zwiekszaj odstep az do szerokosci spacja
        jmp @sc4                ;w przeciwnym przypadku nastepna litera tekstu
@nie_spacja:
        mov bx,offset przemapow ;offset tab. przem. do bx
        xor ah,ah               
        add bx,ax               ;dodaj ascii litery do offsetu tab. przemap.
        sub byte ptr ax,[bx]    ;wylicz nowy kod litery odp. mojemu formatowi.
	                        ;Od kodu ascii litery odejmowana jest wartosc pobrana z tab. przemap.
	                        ;dla danej wartosci ascii. W AX nowy indeks znaku.
	                
        ;mov ah,8               ;fonty 8x8, by uzyskac dostep do danego znaku nalezy pomnozyc
        ;mul ah                 ;przemapowany wczesniej kod znaku przez 8
        xor ah,ah
        shl ax,1
        shl ax,1
        shl ax,1
        mov bx,offset fonty     ;do bx offset tablicy z fontami
        add bx,ax               ;dodaj przesniecie obliczone wczesniej
        add bl,poz_fonta        ;dodaj biezaca pozycje z ktorej kopiujemy kolumne danego znaku
        mov di,320*scroll_y+319 ;policz miejsce w ktore bedziemy kopiowali biezaca kolumne
	                        ;szer. ekranu 320 pomn. przez miejsce od ktorego rysujemy scroll plus
	                        ;319 bo rysujemy w ostatnim pixelu szerokosci ekranu
	                
        mov cl,8                ;8 pikseli do skopiowania 
        mov ah,0
@sc2:
        mov byte ptr al,[bx]	;pobierz pixel z tab fontow
        mov byte ptr es:[di],al ;zapisz do bufora
        add di,320              ;nastepny piksel nastepny wiersz w buforze
        add bx,640              ;nastepny wiersz w tablicy znakow 
        cmp al,0                ;spraw. czy byl piksel
        je  @sc3                ;jak nie to nie zapalaj flagi 
	                
        mov ah,1                ;jak tak to zapal
@sc3:
        loop @sc2               ;kopiuj kolejny piksel
	                
        cmp ah,1                ;jak skopiowalismy przynajmniej jeden piksel to nie zmieniaj na kolejny znak 
	                        ;az do natrafienia calej pustej kolumny
        jne @sc4
@spacja:                        
        inc poz_fonta           ;kolejna kolumna wewn. znaku
        jmp @scexit
@sc4:
        mov poz_fonta,0         ;biezaca kopiowana kolumna byla pusta, czyli nastepny znak
        inc wsk_tekstu
@scexit:
        ret
        ENDP
;-------------------------------------------------------------------------------------------------
  include linia.asm
;-------------------------------------------------------------------------------------------------

end main
