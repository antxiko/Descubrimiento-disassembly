; ==========================================================================
; EL DESCUBRIMIENTO DE AMERICA - MSX - segunda parte: el programa
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS firma: Los caracteres 'A' y 'B', igual que en la primera parte. No los
;   lee nadie.
;   0x4000..0x4002  (2 bytes)

; ----------------------------------------------------------------------
; ==========================================================
; EL DESCUBRIMIENTO DE AMERICA - segunda parte, el programa
; ==========================================================
; El segundo bloque sin cabecera de la cinta, con el mismo
; reparto que el primero: 0x2400 bytes aqui y 0x5300 a 0x8000.
; Ocupa LAS MISMAS direcciones que la primera parte, que para
; entonces ya no existe.
;
; Aqui empieza la travesia. El escenario es un corte del barco
; -128 baldosas de ancho por 52 de alto, en 0x9000- por el que
; se mueve la tripulacion, y hay ademas una pantalla de mapa
; oceanico con los dias, el estado moral y el fisico.
;
; Lo primero que hace, en 0x4037, es leer los seis bytes que la
; primera parte dejo en 0xD6D9: ese es todo el traspaso entre
; las dos mitades del juego.
; ----------------------------------------------------------------------
DATA_firma:
	defb 041h,042h	; 4000

; ----------------------------------------------------------------------
; DATOS punto_de_entrada: La palabra 0x401F: el cargador la lee en 0xD3AD con
;   `ld hl,(0x4002)` y salta ahi.
;   0x4002..0x4004  (2 bytes)
DATA_punto_de_entrada:
	defw 0401fh	; 4002  -> principal

; ----------------------------------------------------------------------
; DATOS hueco_de_cabecera: Doce ceros entre la cabecera y el codigo.
;   0x4004..0x4010  (12 bytes)
DATA_hueco_de_cabecera:
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 4004  ............

; ======================================================================
; CODIGO 0x4010..0x5c3f  (7215 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; --- rutina de servicio: la VRAM entera de una vez -------
; La misma que abre la primera parte, byte a byte. No la llama
; nadie.
; ----------------------------------------------------------------------
vuelca_vram_entera:		; Apaga la pantalla y copia 0x8000-0xBFFF a la VRAM
	call 00041h		;4010   ; BIOS DISSCR - Inhibits the screen display | DISSCR
	ld hl,08000h		;4013
	ld de,00000h		;4016
	ld bc,04000h		;4019
	jp 0005ch		;401c   ; BIOS LDIRVM - Block transfers to VRAM from memory | LDIRVM: 0x4000 bytes a partir de la direccion 0 de VRAM

; ----------------------------------------------------------------------
; =========== ARRANQUE DE LA SEGUNDA PARTE ===============
; ----------------------------------------------------------------------
principal:		; Punto de entrada del bloque
	ld hl,0db88h		;401f   ; la pila, en lo alto de la zona libre
	ld sp,hl			;4022
	ld hl,0cbc6h		;4023   ; las fichas de los barcos, de la copia intacta de 0xCBC6
	ld de,0b02ch		;4026
	ld bc,0002ch		;4029
	ldir		;402c
	ld hl,0f87fh		;402e   ; borra la zona de variables, de 0xF87F a 0xF91E
	ld de,0f91fh		;4031
	call borra_hasta		;4034
	ld hl,0d6d9h		;4037   ; los seis bytes que dejo la primera parte en 0xD6D9: lo comprado alli
	ld de,0f39ah		;403a   ; 0xF39F  MARINEROS la tripulacion, y por tanto cuantos hay
	ld bc,00006h		;403d
	ldir		;4040
	ld a,(0f39fh)		;4042   ; 0xF39F es cuantos van a bordo
	cp 005h		;4045   ; con menos de cinco, la moral empieza tocada
	jp nc,pon_valores_de_partida		;4047
	ld a,002h		;404a   ; 0xF8D5: dos tramos de moral perdidos de salida
	ld (0f8d5h),a		;404c
pon_valores_de_partida:		; Deja las variables como tienen que empezar
	ld a,001h		;404f   ; 0xF8A2: el tercer barco con la vela puesta
	ld (0f8a2h),a		;4051
	ld (0f8a6h),a		;4054   ; 0xF8A6 y 0xF8AA, a uno
	ld (0f8aah),a		;4057
	ld a,005h		;405a   ; 0xF8A4: cinco
	ld (0f8a4h),a		;405c
	ld a,003h		;405f   ; 0xF8A9: tres
	ld (0f8a9h),a		;4061
	ld hl,01e1ch		;4064   ; 0xF8C9: la casilla 0x1E1C, la primera orden
	ld (0f8c9h),hl		;4067
	ld hl,0206eh		;406a   ; 0xF8CC: la casilla 0x206E, la segunda
	ld (0f8cch),hl		;406d
	ld hl,00713h		;4070   ; 0xF8B7 y 0xF8B8: la casilla de salida en la carta, la 0x13,7
	ld (0f8b7h),hl		;4073
	call casilla_del_oceano		;4076   ; se lee la casilla del oceano...
	call aplica_casilla		;4079   ; ...y se aplica lo que traiga
	call coloca_al_nuevo		;407c   ; se coloca a la tripulacion
L_407F:
	call sonido_corto		;407f   ; y se pinta la ventana
	ld a,007h		;4082   ; 0xF8CE: el color del cielo de salida
	ld (0f8ceh),a		;4084
	xor a			;4087   ; 0xF8D0: la fuente de dia
	ld (0f8d0h),a		;4088
	ld a,002h		;408b   ; SCREEN 2
	call 0005fh		;408d   ; BIOS CHGMOD - Switches to given screen mode
	call carga_fuente		;4090   ; primera pintada de la fuente
bucle_principal:		; Catorce llamadas por vuelta, y a empezar otra vez
	call pinta_ventana		;4093   ; la ventana del barco
	call mueve_a_la_tripulacion		;4096   ; el muñeco
	call fin_de_la_travesia		;4099   ; la llegada
	call cambia_de_tripulante		;409c   ; las teclas de orden
	call parpadeo		;409f   ; el balanceo
	call pasa_el_tiempo		;40a2   ; el reloj
	call avanza_la_ruta		;40a5   ; la ruta en la carta
	call quita_punto_de_ruta		;40a8   ; los puntos de ruta
	call tecla_de_orden		;40ab   ; la tecla que da orden
	call anula_orden		;40ae   ; la tecla que la anula
	call luz_de_aviso		;40b1   ; la luz de aviso
	call cambia_el_cielo		;40b4   ; el color del cielo
	call llegada		;40b7   ; la llegada a puerto
	call pantalla_de_desastre		;40ba   ; el desastre, si lo hay
	jp bucle_principal		;40bd
apunta_al_barco:		; Recalcula los punteros que dependen del barco en curso 0xF897
	ld hl,03800h		;40c0   ; 0x3800: la tabla de patrones de sprite
	ld (0f881h),hl		;40c3
	ld hl,0b000h		;40c6   ; ficha del barco: once bytes por barco, cuatro barcos
	ld de,0000bh		;40c9
	call avanza_n_veces		;40cc
	ld (0f893h),hl		;40cf   ; se guarda para quien la necesite
	ld (0f887h),hl		;40d2
	ld hl,0aa60h		;40d5   ; sprites del barco: 0x168 bytes por barco
	ld de,00168h		;40d8
	call avanza_n_veces		;40db
	ld (0f895h),hl		;40de
	ld (0f87fh),hl		;40e1
	ret			;40e4
avanza_n_veces:		; HL += DE, repetido (0xF897) veces
	ld a,(0f897h)		;40e5   ; 0xF897 es el barco en curso
L_40E8:
	ld (0f883h),a		;40e8   ; --- un paso por barco ---
	cp 000h		;40eb   ; con cero pasos, HL se queda como esta
	ret z			;40ed
	add hl,de			;40ee
	ld a,(0f883h)		;40ef
	dec a			;40f2
	jp L_40E8		;40f3
borra_hasta:		; Pone a cero de HL a DE
	xor a			;40f6
	ld (hl),a			;40f7
	inc hl			;40f8
	rst 20h			;40f9   ; DCOMPR compara HL con DE
	jp nz,borra_hasta		;40fa
	ret			;40fd
carga_fuente:		; Sube los 0x800 de patrones y los 0x800 de colores a los tres tercios
	ld hl,00800h		;40fe   ; 0x800 bytes: 256 baldosas de ocho filas
	ld (0f883h),hl		;4101
	ld hl,00000h		;4104   ; a la tabla de patrones
	ld (0f881h),hl		;4107
	ld hl,08000h		;410a   ; los patrones, en 0x8000
	ld (0f87fh),hl		;410d
	call vuelca_tres_tercios		;4110
	ld hl,02000h		;4113   ; y a la tabla de colores
	ld (0f881h),hl		;4116
	ld hl,08800h		;4119   ; los colores, en 0x8800
	ld (0f87fh),hl		;411c
	jp vuelca_tres_tercios		;411f
campo_del_barco:		; Devuelve el byte A-1 de la ficha del barco en 0xF887
	dec a			;4122   ; los campos se cuentan desde 1
	ld e,a			;4123
	xor a			;4124
	ld d,a			;4125
	ld hl,(0f887h)		;4126   ; la ficha del barco en curso
	add hl,de			;4129
	ld a,(hl)			;412a   ; y el campo pedido
	ret			;412b
parpadeo:		; Alterna 0xF8B1 cada tres vueltas: el balanceo de los muñecos
	ld a,(0f8b2h)		;412c   ; 0xF8B2 cuenta las vueltas
	inc a			;412f
	ld (0f8b2h),a		;4130
	cp 003h		;4133   ; una de cada tres
	ret nz			;4135
	xor a			;4136
	ld (0f8b2h),a		;4137
	ld a,(0f8b1h)		;413a   ; 0xF8B1 va y viene entre 0 y 1
	inc a			;413d
	ld (0f8b1h),a		;413e
	cp 001h		;4141
	ret z			;4143
	xor a			;4144
	ld (0f8b1h),a		;4145
	ret			;4148
baja_cuatro:		; (HL) += 4
	ld a,(hl)			;4149
	add a,004h		;414a
	ld (hl),a			;414c
	ret			;414d
sube_cuatro:		; (HL) -= 4
	ld a,(hl)			;414e
	sub 004h		;414f
	ld (hl),a			;4151
	ret			;4152

; ----------------------------------------------------------------------
; --- por donde se puede andar -----------------------------
; A diferencia de la primera parte, aqui no hay una lista de
; baldosas solidas por pantalla sino UNA sola, porque el
; escenario es un unico mapa: el corte del barco. Lo que
; devuelve la rutina no es "si o no" sino un tipo de terreno,
; porque con la escalera y con el mastil hay que hacer cosas
; distintas que con el suelo.
; ----------------------------------------------------------------------
tipo_de_baldosa:		; Clasifica la baldosa que hay bajo (0xF899, 0xF89A)
	call baldosa_en		;4153   ; devuelve 0 = se puede pisar, 1 = suelo, 3 = pared, 4 = escalera, 5 = especial
	ld (0f88dh),a		;4156   ; se guarda el numero de baldosa para las comprobaciones de abajo
	cp 00ah		;4159   ; 0x0A, 0x0D, 0x09, 0x0F, 0x07, 0x08, 0x10, 0x11 y 0x0E: suelo
	jp z,terreno_1		;415b
	cp 00dh		;415e
	jp z,terreno_1		;4160
	cp 009h		;4163
	jp z,terreno_1		;4165
	cp 00fh		;4168
	jp z,terreno_1		;416a
	cp 007h		;416d
	jp z,terreno_1		;416f
	cp 008h		;4172
	jp z,terreno_1		;4174
	cp 010h		;4177
	jp z,terreno_1		;4179
	cp 011h		;417c
	jp z,terreno_1		;417e
	cp 00eh		;4181
	jp z,terreno_1		;4183
	cp 027h		;4186   ; 0x27: el borde de una cubierta
	jp z,L_41FF		;4188
	cp 01bh		;418b   ; 0x1B: la escalera
	jp z,mira_la_escalera		;418d
	cp 033h		;4190   ; 0x33: el mastil
	jp z,mira_el_mastil		;4192
	cp 034h		;4195   ; 0x34: la borda
	jp z,mira_la_borda		;4197
	cp 031h		;419a   ; 0x31, 0xA4, 0xA3, 0x91, 0x5F, 0x0C, 0x6D, 0x4A y 0xB8: pared
	jp z,terreno_3		;419c
	cp 0a4h		;419f
	jp z,terreno_3		;41a1
	cp 0a3h		;41a4
	jp z,terreno_3		;41a6
	cp 091h		;41a9
	jp z,terreno_3		;41ab
	cp 05fh		;41ae
	jp z,terreno_3		;41b0
	cp 00ch		;41b3
	jp z,terreno_3		;41b5
	cp 06dh		;41b8
	jp z,terreno_3		;41ba
	cp 04ah		;41bd
	jp z,terreno_3		;41bf
	cp 0b8h		;41c2
	jp z,terreno_3		;41c4
	cp 0fbh		;41c7   ; 0xFB y 0xFC: dos baldosas mas de suelo
	jp z,terreno_1		;41c9
	cp 0fch		;41cc
	jp z,terreno_1		;41ce
	cp 0fah		;41d1   ; 0xFA y 0xF9: la baldosa que suma un punto
	jp z,punto_de_bonus		;41d3
	cp 0f9h		;41d6
	jp z,punto_de_bonus		;41d8
L_41DB:
	xor a			;41db   ; por lo demas, se puede pasar
	ret			;41dc
terreno_1:		; Suelo
	ld a,001h		;41dd
	ret			;41df
terreno_2:		; Escalera vista de frente
	ld a,002h		;41e0
	ret			;41e2
terreno_3:		; Pared
	ld a,003h		;41e3
	ret			;41e5
terreno_4:		; Escalera por la que se sube
	ld a,004h		;41e6
	ret			;41e8
terreno_5:		; Terreno especial
	ld a,005h		;41e9
	ret			;41eb
mira_la_escalera:		; La baldosa 0x1B solo es escalera si se viene desde arriba
	ld a,(0f891h)		;41ec   ; 0xF891 es la direccion del mando; 7 es la izquierda
	cp 007h		;41ef
	jp nz,L_41FF		;41f1
	xor a			;41f4
	sbc hl,de		;41f5   ; mira la baldosa que hay justo antes
	call 0004ah		;41f7   ; BIOS RDVRM - Reads the content of VRAM
	cp 033h		;41fa   ; otra escalera: entonces si se puede subir
	jp z,terreno_4		;41fc
L_41FF:
	ld a,(0f89bh)		;41ff   ; 0xF89B dice si el muñeco esta trepando
	cp 001h		;4202
	jp z,terreno_2		;4204
	jp terreno_3		;4207
mira_el_mastil:		; La baldosa 0x33 solo se trepa si se viene desde abajo
	ld a,(0f891h)		;420a   ; 0xF891 a 3 es la derecha
	cp 003h		;420d
	jp nz,L_41DB		;420f
	add hl,de			;4212
	call 0004ah		;4213   ; BIOS RDVRM - Reads the content of VRAM | la baldosa siguiente
	cp 01bh		;4216   ; con otra escalera detras, se trepa
	jp z,terreno_4		;4218
	ld a,(0f89bh)		;421b
	cp 001h		;421e
	jp z,L_41DB		;4220
	jp terreno_3		;4223
mira_la_borda:		; La 0x34 se pasa solo si no se esta trepando
	ld a,(0f89bh)		;4226
	and a			;4229
	jp z,terreno_3		;422a
	jp L_41DB		;422d
punto_de_bonus:		; Las baldosas 0xF9 y 0xFA suman en 0xF8AB
	ld a,(0f8abh)		;4230
	inc a			;4233
	ld (0f8abh),a		;4234
	jp terreno_1		;4237
baldosa_en:		; Lee de la VRAM la baldosa de la columna 0xF899 y la fila 0xF89A
	ld a,(0f899h)		;423a   ; 0xF899 es la X en pixeles...
	srl a		;423d   ; ...que dividida entre ocho da la columna
	srl a		;423f
	srl a		;4241
	ld e,a			;4243
	xor a			;4244
	ld d,a			;4245
	ld hl,01800h		;4246   ; 0x1800: la tabla de nombres
	add hl,de			;4249
	ld a,(0f89ah)		;424a   ; y 0xF89A la Y, con el mismo apaño
	srl a		;424d
	srl a		;424f
	srl a		;4251
	ld de,00020h		;4253   ; cada fila son 0x20 baldosas
L_4256:
	cp 000h		;4256   ; --- baja tantas filas como haga falta ---
	jp z,0004ah		;4258   ; BIOS RDVRM - Reads the content of VRAM | y RDVRM devuelve el numero de baldosa
	add hl,de			;425b
	dec a			;425c
	jp L_4256		;425d
vuelca_tres_tercios:		; Copia (0xF87F) a (0xF881) y repite en +0x800 y +0x1000
	call copia_vram		;4260   ; primer tercio
	call baja_un_tercio		;4263
	call copia_vram		;4266   ; segundo
	call baja_un_tercio		;4269
copia_vram:		; LDIRVM con los tres punteros de 0xF87F, 0xF881 y 0xF883
	ld hl,(0f87fh)		;426c   ; tercero, por caida
	ld de,(0f881h)		;426f
	ld bc,(0f883h)		;4273
	jp 0005ch		;4277   ; BIOS LDIRVM - Block transfers to VRAM from memory
baja_un_tercio:		; Suma 0x800 al destino en VRAM
	ld hl,(0f881h)		;427a
	ld a,h			;427d   ; basta con sumar 8 al byte alto
	add a,008h		;427e
	ld h,a			;4280
	ld (0f881h),hl		;4281
	ret			;4284
pinta_ventana:		; Recorta 32x24 baldosas del mapa del barco y las sube a la VRAM
	ld hl,01800h		;4285   ; primero se baja la tabla de nombres de la VRAM a 0xB058 para trabajar
	ld de,0b058h		;4288
	ld (0f881h),de		;428b
	ld bc,00300h		;428f
	call 00059h		;4292   ; BIOS LDIRMV - Block transfers to memory from VRAM | LDIRMV: de la VRAM a la RAM
	di			;4295   ; el montaje se hace con la interrupcion cerrada
	ld hl,09000h		;4296   ; el mapa esta en 0x9000; 0xF88F es la columna y 0xF890 la fila de arriba
	ld a,(0f88fh)		;4299
	ld e,a			;429c
	xor a			;429d
	ld d,a			;429e
	add hl,de			;429f
	ld de,00080h		;42a0   ; el mapa tiene 128 baldosas de ancho: por eso el paso entre filas es 0x80
	ld a,(0f890h)		;42a3
	cp 000h		;42a6
	jp z,L_42AF		;42a8
	ld b,a			;42ab
L_42AC:
	add hl,de			;42ac   ; --- baja tantas filas como diga 0xF890 ---
	djnz L_42AC		;42ad
L_42AF:
	xor a			;42af   ; 0xF885 cuenta las filas copiadas
	ld (0f885h),a		;42b0
	ld (0f87fh),hl		;42b3
L_42B6:
	ld hl,(0f87fh)		;42b6   ; --- una fila por vuelta ---
	ld de,(0f881h)		;42b9
	ld bc,00020h		;42bd   ; 32 baldosas: lo que se ve de ancho
	ldir		;42c0
	ld de,00080h		;42c2   ; en el mapa la fila siguiente esta 0x80 mas alla...
	ld hl,(0f87fh)		;42c5
	add hl,de			;42c8
	ld (0f87fh),hl		;42c9
	ld de,00020h		;42cc   ; ...pero en la pantalla, solo 0x20
	ld hl,(0f881h)		;42cf
	add hl,de			;42d2
	ld (0f881h),hl		;42d3
	ld a,(0f885h)		;42d6
	inc a			;42d9
	ld (0f885h),a		;42da
	cp 018h		;42dd   ; veinticuatro filas
	jp nz,L_42B6		;42df
	jp primera_pintada		;42e2   ; y se sube todo de una vez

; ----------------------------------------------------------------------
; --- el muñeco por el barco ------------------------------
; ----------------------------------------------------------------------
mueve_a_la_tripulacion:		; Anima y desplaza al muñeco segun el mando
	call apunta_al_barco		;42e5   ; punteros al dia
	call lee_mando		;42e8   ; la direccion del mando
	cp 001h		;42eb   ; 1 = arriba
	jp z,L_430E		;42ed
	cp 003h		;42f0   ; 3 = derecha
	jp z,L_4346		;42f2
	cp 005h		;42f5   ; 5 = abajo
	jp z,L_435F		;42f7
	cp 007h		;42fa   ; 7 = izquierda
	jp z,L_4378		;42fc
	ld a,004h		;42ff   ; sin direccion, el fotograma se queda a cero
	call campo_del_barco		;4301
	cp 000h		;4304
	jp z,pinta_al_marinero		;4306
	xor a			;4309
	ld (hl),a			;430a
	jp pinta_al_marinero		;430b
L_430E:
	ld a,003h		;430e   ; --- arriba ---
	call campo_del_barco		;4310
	cp 001h		;4313
	jp nz,L_431E		;4315
	call anda_a_la_izquierda		;4318   ; sube si la baldosa de encima lo permite
	jp L_4391		;431b
L_431E:
	ld a,(hl)			;431e
	cp 000h		;431f
	jp nz,L_4331		;4321
L_4324:
	ld a,(hl)			;4324   ; el fotograma del paso avanza de 0 a 3...
	inc a			;4325
	ld (hl),a			;4326
	cp 004h		;4327
	jp nz,L_4340		;4329
	xor a			;432c
	ld (hl),a			;432d
	jp L_4340		;432e
L_4331:
	ld a,(hl)			;4331   ; ...o retrocede, segun hacia donde se ande
	cp 000h		;4332
	jp z,L_433D		;4334
	ld a,(hl)			;4337
	dec a			;4338
	ld (hl),a			;4339
	jp L_4340		;433a
L_433D:
	ld a,003h		;433d
	ld (hl),a			;433f
L_4340:
	inc hl			;4340
	xor a			;4341
	ld (hl),a			;4342
	jp pinta_al_marinero		;4343
L_4346:
	ld a,003h		;4346   ; --- abajo ---
	call campo_del_barco		;4348
	cp 002h		;434b
	jp nz,L_4356		;434d
	call anda_hacia_abajo		;4350
	jp L_4391		;4353
L_4356:
	ld a,(hl)			;4356
	cp 001h		;4357
	jp z,L_4324		;4359
	jp L_4331		;435c
L_435F:
	ld a,003h		;435f   ; --- izquierda ---
	call campo_del_barco		;4361
	cp 003h		;4364
	jp nz,L_436F		;4366
	call anda_hacia_abajo_libre		;4369
	jp L_4391		;436c
L_436F:
	ld a,(hl)			;436f
	cp 000h		;4370
	jp z,L_4331		;4372
	jp L_4324		;4375
L_4378:
	ld a,003h		;4378   ; --- derecha ---
	call campo_del_barco		;437a
	cp 000h		;437d
	jp nz,L_4388		;437f
	call anda_hacia_arriba		;4382
	jp L_4391		;4385
L_4388:
	ld a,(hl)			;4388
	cp 001h		;4389
	jp z,L_4331		;438b
	jp L_4324		;438e
L_4391:
	ld a,004h		;4391   ; al andar de verdad, un fotograma mas
	call campo_del_barco		;4393
	inc a			;4396
	ld (hl),a			;4397
	cp 004h		;4398
	jp nz,pinta_al_marinero		;439a
	xor a			;439d
	ld (hl),a			;439e
	jp pinta_al_marinero		;439f
anda_hacia_arriba:		; Sube ocho pixeles o trepa, si la baldosa deja
	ld a,(0f89bh)		;43a2   ; trepando se sube por otro sitio
	cp 001h		;43a5
	jp z,trepa_hacia_arriba		;43a7
	ld a,001h		;43aa   ; la columna del muñeco, ocho pixeles a la izquierda
	call campo_del_barco		;43ac
	sub 008h		;43af
	ld (0f899h),a		;43b1
	inc hl			;43b4
	ld a,(hl)			;43b5
	add a,024h		;43b6   ; y la fila, 0x24 mas abajo: los pies
	ld (0f89ah),a		;43b8
	call tipo_de_baldosa		;43bb   ; que hay ahi
	ld (0f87fh),a		;43be
	ld a,(0f88dh)		;43c1   ; si es mastil, se mira si se puede trepar
	cp 033h		;43c4
	call z,corre_ventana_abajo		;43c6
	ld a,(0f87fh)		;43c9
	cp 000h		;43cc   ; terreno libre: no hay nada que hacer
	ret z			;43ce
	cp 004h		;43cf   ; terreno 4: escalera, y entonces se trepa
	jp nz,L_4421		;43d1
	ld a,001h		;43d4
	call campo_del_barco		;43d6
	bit 2,a		;43d9
	jp z,L_43E1		;43db
	call sube_cuatro		;43de   ; si va hacia la derecha, se le corrige
L_43E1:
	call sube_ocho		;43e1   ; sube ocho pixeles
	call empieza_a_trepar		;43e4
	jp trepa_hacia_arriba		;43e7
empieza_a_trepar:		; Pone al muñeco en modo escalada
	ld a,001h		;43ea   ; 0xF89B: trepando
	ld (0f89bh),a		;43ec
	ld (0f89ch),a		;43ef   ; 0xF89C: por que lado
	call campo_del_barco		;43f2
	ld (0f899h),a		;43f5
	inc hl			;43f8
	ld a,(hl)			;43f9
	add a,02ch		;43fa   ; la fila, 0x2C mas abajo
	ld (0f89ah),a		;43fc
	call tipo_de_baldosa		;43ff
	cp 000h		;4402   ; con terreno libre, se baja
	jp z,L_4414		;4404
	ld a,002h		;4407
	call campo_del_barco		;4409
	bit 2,a		;440c
	call nz,baja_cuatro		;440e
	jp baja_ocho		;4411
L_4414:
	ld a,002h		;4414   ; y si no, se sube
	call campo_del_barco		;4416
	bit 2,a		;4419
	call nz,sube_cuatro		;441b
	jp sube_ocho		;441e
L_4421:
	ld a,001h		;4421   ; --- el muñeco esta al borde de la ventana ---
	call campo_del_barco		;4423
	cp 008h		;4426   ; baldosa 8: por ahi no se sube
	ret z			;4428
	bit 2,a		;4429   ; bit 2: la columna esta a media baldosa
	jp z,sube_cuatro		;442b
	ld a,(0f88fh)		;442e   ; 0xF88F a cero: la ventana ya esta al borde
	cp 000h		;4431
	jp z,sube_cuatro		;4433
	ld a,(hl)			;4436   ; por encima de la columna 0x50 no se corre
	cp 050h		;4437
	jp nc,sube_cuatro		;4439
	ld hl,0f88fh		;443c   ; y si no, se corre una columna
	dec (hl)			;443f
	jp repinta		;4440
anda_hacia_abajo:		; Baja ocho pixeles, o corre la ventana si toca
	ld a,(0f89bh)		;4443   ; trepando se baja por otro sitio
	cp 001h		;4446
	jp z,trepa_hacia_abajo		;4448
	ld a,001h		;444b   ; la columna, 0x10 a la derecha
	call campo_del_barco		;444d
	add a,010h		;4450
	ld (0f899h),a		;4452
	inc hl			;4455
	ld a,(hl)			;4456
	add a,024h		;4457   ; y la fila, 0x24 mas abajo
	ld (0f89ah),a		;4459
	call tipo_de_baldosa		;445c
	cp 000h		;445f   ; terreno libre: nada que hacer
	ret z			;4461
	cp 004h		;4462   ; terreno 4: escalera
	jp nz,L_44B7		;4464
	ld a,001h		;4467
	call campo_del_barco		;4469
	bit 2,a		;446c
	jp z,L_4474		;446e
	call baja_cuatro		;4471
L_4474:
	call baja_ocho		;4474
	call empieza_a_bajar		;4477
	jp corre_ventana_abajo		;447a
empieza_a_bajar:		; Pone al muñeco en modo escalada hacia abajo
	xor a			;447d   ; 0xF89C a cero: agarrado por el otro lado
	ld (0f89ch),a		;447e
	ld a,001h		;4481   ; 0xF89B: trepando
	ld (0f89bh),a		;4483
	call campo_del_barco		;4486   ; la columna, 0x18 a la derecha
	add a,018h		;4489
	ld (0f899h),a		;448b
	inc hl			;448e   ; y la fila, 0x28 mas abajo
	ld a,(hl)			;448f
	add a,028h		;4490
	ld (0f89ah),a		;4492
	call tipo_de_baldosa		;4495   ; que hay ahi
	cp 000h		;4498
	jp z,L_44AA		;449a   ; con terreno libre, se baja
	ld a,002h		;449d
	call campo_del_barco		;449f
	bit 2,a		;44a2   ; bit 2: media baldosa
	call nz,sube_cuatro		;44a4
	jp sube_ocho		;44a7   ; y si no, se sube
L_44AA:
	ld a,002h		;44aa
	call campo_del_barco		;44ac
	bit 2,a		;44af
	call nz,baja_cuatro		;44b1
	jp baja_ocho		;44b4
L_44B7:
	ld a,001h		;44b7   ; --- el muñeco esta en el borde de la ventana ---
	call campo_del_barco		;44b9
	bit 2,a		;44bc
	jp z,baja_cuatro		;44be
	ld a,(0f88fh)		;44c1   ; 0x60 es el tope del scroll a la derecha
	cp 060h		;44c4
	jp z,baja_cuatro		;44c6
	ld a,(hl)			;44c9
	cp 0b0h		;44ca   ; por debajo de la columna 0xB0 no se corre la ventana
	jp c,baja_cuatro		;44cc
	ld hl,0f88fh		;44cf   ; y si no, se corre una columna
	inc (hl)			;44d2
	jp repinta		;44d3
anda_a_la_izquierda:		; Ocho pixeles a la izquierda, o corre la ventana
	ld a,(0f89bh)		;44d6   ; trepando no se anda
	cp 001h		;44d9
	ret z			;44db
	ld a,001h		;44dc
	call campo_del_barco		;44de   ; la columna del muñeco
	ld (0f899h),a		;44e1
	inc hl			;44e4
	ld a,(hl)			;44e5
	add a,020h		;44e6   ; y la fila, 0x20 mas abajo
	ld (0f89ah),a		;44e8
	ld a,(0f899h)		;44eb
	bit 2,a		;44ee   ; con la columna en un multiplo impar de cuatro, se ajusta
	jp nz,L_4532		;44f0
	call tipo_de_baldosa		;44f3   ; terreno 1 es suelo: por ahi no se pasa
	cp 001h		;44f6
	ret nz			;44f8
	ld a,(0f899h)		;44f9   ; ocho pixeles mas alla
	add a,008h		;44fc
L_44FE:
	ld (0f899h),a		;44fe   ; --- mira otra vez ---
	call tipo_de_baldosa		;4501
	cp 001h		;4504
	ret nz			;4506
	ld hl,0f899h		;4507
	call sube_ocho		;450a
	call baldosa_en		;450d   ; que baldosa hay ahi
	cp 033h		;4510   ; 0x33 es el mastil: no se pasa
	ret z			;4512
	ld a,002h		;4513
	call campo_del_barco		;4515
	bit 2,a		;4518
	jp z,sube_cuatro		;451a
	ld a,(0f890h)		;451d   ; 0xF890 a cero: la ventana ya esta arriba del todo
	cp 000h		;4520
	jp z,sube_cuatro		;4522
	ld a,(hl)			;4525   ; por debajo de la fila 0x50 no se corre
	cp 050h		;4526
	jp nc,sube_cuatro		;4528
	ld hl,0f890h		;452b   ; y si no, se sube una fila
	dec (hl)			;452e
	jp repinta		;452f
L_4532:
	add a,004h		;4532
	jp L_44FE		;4534
anda_hacia_abajo_libre:		; Ocho pixeles hacia abajo, o corre la ventana
	ld a,(0f89bh)		;4537   ; trepando no se anda
	cp 001h		;453a
	ret z			;453c
	ld a,001h		;453d
	call campo_del_barco		;453f
	ld (0f899h),a		;4542
	inc hl			;4545
	ld a,(hl)			;4546
	add a,028h		;4547   ; la fila, 0x28 mas abajo
	ld (0f89ah),a		;4549
	ld a,(0f899h)		;454c
	bit 2,a		;454f
	jp nz,L_4596		;4551
	call tipo_de_baldosa		;4554   ; terreno 1 es suelo
	cp 001h		;4557
	ret nz			;4559
	ld a,(0f899h)		;455a
	add a,008h		;455d
L_455F:
	ld (0f899h),a		;455f
	call tipo_de_baldosa		;4562
	cp 001h		;4565
	ret nz			;4567
	ld hl,0f899h		;4568
	call sube_ocho		;456b
	call baldosa_en		;456e
	cp 033h		;4571   ; 0x33 es el mastil
	ret z			;4573
	ld a,002h		;4574
	call campo_del_barco		;4576
	bit 2,a		;4579
	jp nz,baja_cuatro		;457b
	ld a,(0f890h)		;457e   ; 0x1C es el tope del scroll hacia abajo
	cp 01ch		;4581
	jp z,baja_cuatro		;4583
	ld a,(hl)			;4586   ; por encima de la fila 0x70 no se corre
	cp 070h		;4587
	jp c,baja_cuatro		;4589
	ld hl,0f890h		;458c
	inc (hl)			;458f
repinta:		; Recompone la ventana y repone los punteros
	call pinta_ventana		;4590
	jp apunta_al_barco		;4593
L_4596:
	add a,004h		;4596
	jp L_455F		;4598
corre_ventana_izquierda:		; Una columna del mapa hacia la izquierda
	ld a,001h		;459b
	call campo_del_barco		;459d
	bit 2,a		;45a0
	call z,sube_cuatro		;45a2
	ld a,(0f88fh)		;45a5   ; 0xF88F a cero: ya esta al borde
	cp 000h		;45a8
	jp z,sube_ocho		;45aa
	ld a,(hl)			;45ad   ; por encima de la columna 0x50 no se corre
	cp 050h		;45ae
	jp nc,sube_ocho		;45b0
	ld hl,0f88fh		;45b3
	dec (hl)			;45b6
	jp repinta		;45b7
sube_ocho:		; (HL) -= 8
	ld a,(hl)			;45ba
	sub 008h		;45bb
	ld (hl),a			;45bd
	ret			;45be
baja_ocho:		; (HL) += 8
	ld a,(hl)			;45bf
	add a,008h		;45c0
	ld (hl),a			;45c2
	ret			;45c3
corre_ventana_derecha:		; Una columna del mapa hacia la derecha
	ld a,001h		;45c4
	call campo_del_barco		;45c6
	bit 2,a		;45c9
	call nz,baja_cuatro		;45cb
	ld a,(0f88fh)		;45ce   ; 0x60 es el tope
	cp 060h		;45d1
	jp z,baja_ocho		;45d3
	ld a,(hl)			;45d6   ; por debajo de la columna 0xB0 no se corre
	cp 0b0h		;45d7
	jp c,baja_ocho		;45d9
	ld hl,0f88fh		;45dc
	inc (hl)			;45df
	jp repinta		;45e0
corre_ventana_arriba:		; Una fila del mapa hacia arriba
	ld a,002h		;45e3   ; el campo 2 de la ficha: la Y
	call campo_del_barco		;45e5
	bit 2,a		;45e8   ; bit 2: si no esta a media baldosa, se sube
	call z,sube_cuatro		;45ea
	ld a,(0f890h)		;45ed   ; 0xF890 a cero: ya esta arriba del todo
	cp 000h		;45f0
	jp z,sube_ocho		;45f2
	ld a,(hl)			;45f5   ; por encima de la fila 0x50 no se corre
	cp 050h		;45f6
	jp nc,sube_ocho		;45f8
	ld hl,0f890h		;45fb   ; y si no, una fila menos
	dec (hl)			;45fe
	jp repinta		;45ff
corre_ventana_abajo:		; Una fila del mapa hacia abajo
	ld a,002h		;4602   ; el campo 2 de la ficha: la Y
	call campo_del_barco		;4604
	bit 2,a		;4607   ; bit 2: si esta a media baldosa, se baja
	call nz,baja_cuatro		;4609
	ld a,(0f890h)		;460c   ; 0x1C es el tope
	cp 01ch		;460f
	jp z,baja_ocho		;4611
	ld a,(hl)			;4614   ; por encima de la fila 0x70 no se corre
	cp 070h		;4615
	jp c,baja_ocho		;4617
	ld hl,0f890h		;461a   ; y si no, una fila mas
	inc (hl)			;461d
	jp repinta		;461e
trepa_hacia_arriba:		; El muñeco sube por la escala o el mastil
	ld a,(0f89ch)		;4621
	cp 001h		;4624   ; 0xF89C dice por que lado esta agarrado
	jp z,L_4638		;4626
	ld a,(0f8aeh)		;4629   ; 0xF8AE cuenta los tramos ya trepados
	cp 003h		;462c
	ret c			;462e
	ld a,001h		;462f
	ld (0f89ch),a		;4631
	xor a			;4634
	ld (0f8aeh),a		;4635
L_4638:
	call cuenta_tramo		;4638   ; un tramo mas
	call corre_ventana_izquierda		;463b
	call corre_ventana_arriba		;463e
	ld a,001h		;4641   ; la columna, ocho a la izquierda
	call campo_del_barco		;4643
	sub 008h		;4646
	ld (0f899h),a		;4648
	inc hl			;464b
	ld a,(hl)			;464c
	add a,024h		;464d   ; y la fila, 0x24 mas abajo
	ld (0f89ah),a		;464f
	call tipo_de_baldosa		;4652   ; terreno 4: escalera; se sigue trepando
	cp 004h		;4655
	jp z,L_4671		;4657
	call ocho_a_la_derecha		;465a
	call tipo_de_baldosa		;465d
	cp 004h		;4660
	jp z,L_4671		;4662
	call ocho_a_la_derecha		;4665
	call tipo_de_baldosa		;4668
	cp 004h		;466b
	jp z,L_4671		;466d
	ret			;4670
L_4671:
	xor a			;4671   ; y si no, se suelta y se pone de pie
	ld (0f89bh),a		;4672
	ld (0f8aeh),a		;4675
	call corre_ventana_izquierda		;4678
	call corre_ventana_izquierda		;467b
	jp corre_ventana_arriba		;467e
trepa_hacia_abajo:		; El muñeco baja por la escala o el mastil
	ld a,(0f89ch)		;4681   ; 0xF89C dice por que lado esta agarrado
	and a			;4684
	jp z,L_4696		;4685
	ld a,(0f8aeh)		;4688   ; 0xF8AE cuenta los tramos ya trepados
	cp 003h		;468b   ; con menos de tres, se sigue igual
	ret c			;468d
	xor a			;468e   ; se cambia de lado
	ld (0f89ch),a		;468f
	xor a			;4692
	ld (0f8aeh),a		;4693   ; y se reinicia la cuenta de tramos
L_4696:
	call cuenta_tramo		;4696   ; un tramo mas
	call corre_ventana_derecha		;4699   ; se corre la ventana si hace falta
	call corre_ventana_abajo		;469c
	ld a,001h		;469f   ; la columna, ocho a la derecha
	call campo_del_barco		;46a1
	add a,008h		;46a4
	ld (0f899h),a		;46a6
	inc hl			;46a9
	ld a,(hl)			;46aa
	add a,024h		;46ab   ; y la fila, 0x24 mas abajo
	ld (0f89ah),a		;46ad
	call tipo_de_baldosa		;46b0   ; terreno 4: escalera; se sigue
	cp 004h		;46b3
	jp z,L_46CF		;46b5
	call ocho_a_la_derecha		;46b8   ; se prueba ocho pixeles mas alla
	call tipo_de_baldosa		;46bb
	cp 004h		;46be
	jp z,L_46CF		;46c0
	call ocho_a_la_derecha		;46c3
	call tipo_de_baldosa		;46c6
	cp 004h		;46c9
	jp z,L_46CF		;46cb
	ret			;46ce
L_46CF:
	xor a			;46cf   ; y al acabar, se suelta
	ld (0f89bh),a		;46d0
	ld (0f8aeh),a		;46d3
	call corre_ventana_derecha		;46d6   ; tres pasos a la derecha para dejarle de pie
	call corre_ventana_derecha		;46d9
	call corre_ventana_derecha		;46dc
	jp corre_ventana_abajo		;46df
ocho_a_la_derecha:		; 0xF899 += 8: la baldosa de al lado
	ld a,(0f899h)		;46e2
	add a,008h		;46e5
	ld (0f899h),a		;46e7
	ret			;46ea
cuenta_tramo:		; 0xF8AE++: los tramos trepados
	ld hl,0f8aeh		;46eb
	inc (hl)			;46ee
	ret			;46ef

; ----------------------------------------------------------------------
; --- el dibujo del muñeco --------------------------------
; Igual que en la primera parte: dieciseis piezas de sprite de
; 8x8 colocadas a mano, y por eso hay una escalerilla de
; rutinas que no hacen mas que mover el cursor.
; ----------------------------------------------------------------------
pinta_al_marinero:		; Deja al muñeco en su sitio, con su sprite y su color
	call apunta_al_barco		;46f0   ; punteros al dia
	ld a,003h		;46f3   ; el campo 3 de la ficha es el estado
	call campo_del_barco		;46f5
	cp 002h		;46f8   ; estado 2: cayendo
	jp z,pinta_cayendo		;46fa
	ld a,(hl)			;46fd   ; estado 0: quieto
	cp 000h		;46fe
	jp z,pinta_quieto		;4700
	ld a,(0d6d8h)		;4703   ; 0xD6D8 sobrevive entre las dos partes del juego
	cp 000h		;4706
	call nz,alterna_d6d8		;4708
coloca_la_figura:		; Deja el sprite base donde toca segun el estado
	ld a,003h		;470b
	call campo_del_barco		;470d
	cp 003h		;4710   ; estado 3: la figura no se mueve de sitio
	jp z,L_472B		;4712
	ld a,(hl)			;4715
	cp 001h		;4716   ; estado 1: la variante de 0x47F5
	jp z,L_47F5		;4718
	ld hl,(0f87fh)		;471b
	ld (0f889h),hl		;471e
	ld de,000f0h		;4721   ; 0xF0: el desplazamiento hasta el sprite de esta postura
L_4724:
	ld hl,(0f87fh)		;4724
	add hl,de			;4727
	ld (0f87fh),hl		;4728
L_472B:
	ld hl,00078h		;472b   ; 0x78: la altura de la figura
	ld (0f883h),hl		;472e
	call copia_vram		;4731   ; sube el sprite a la VRAM
	call pon_sprite		;4734   ; elige el patron que toca
	call pon_sprite_de_brazo		;4737   ; y el brazo
	ld hl,01b00h		;473a   ; 0x1B00: la tabla de atributos de sprite
	ld (0f885h),hl		;473d
	xor a			;4740   ; 0xF881 cuenta las piezas ya puestas
	ld (0f881h),a		;4741
	ld hl,(0f887h)		;4744   ; X e Y del muñeco, de su propia ficha
	ld a,(hl)			;4747
	ld (0f880h),a		;4748
	inc hl			;474b
	ld a,(hl)			;474c
	ld (0f87fh),a		;474d
	call patron_base		;4750   ; y a partir de aqui, las dieciseis piezas
	call fila_de_cuatro		;4753   ; los pies
	call ocho_abajo		;4756
	call patron_mas_0		;4759   ; las piernas
	call fila_de_cuatro		;475c
	call ocho_arriba		;475f
	call dieciseis_derecha		;4762
	call patron_mas_10		;4765
	call fila_de_dos		;4768   ; el cuerpo
	call ocho_abajo		;476b
	call patron_mas_8		;476e
	call fila_de_dos		;4771
	call ocho_arriba		;4774
	call dieciseis_izquierda		;4777
	call patron_mas_12		;477a   ; la cabeza
	call remate_de_figura		;477d
	call dieciseis_derecha		;4780
	call dieciseis_derecha		;4783
	call patron_mas_16		;4786
	call pieza_suelta		;4789   ; y los brazos
	call ocho_abajo		;478c
	call patron_mas_15		;478f
	call pieza_suelta		;4792
	call ocho_arriba		;4795
	call patron_mas_18		;4798
	call ultima_pieza		;479b
	call ocho_abajo		;479e
	call patron_mas_17		;47a1
	jp ultima_pieza		;47a4
ocho_abajo:		; Y += 8
	ld a,(0f880h)		;47a7
	add a,008h		;47aa
	ld (0f880h),a		;47ac
	ret			;47af
ocho_arriba:		; Y -= 8
	ld a,(0f880h)		;47b0
	sub 008h		;47b3
	ld (0f880h),a		;47b5
	ret			;47b8
dieciseis_derecha:		; X += 0x10
	ld a,(0f87fh)		;47b9
	add a,010h		;47bc
	ld (0f87fh),a		;47be
	ret			;47c1
dieciseis_izquierda:		; X -= 0x10
	ld a,(0f87fh)		;47c2
	sub 010h		;47c5
	ld (0f87fh),a		;47c7
	ret			;47ca
pinta_cayendo:		; Variante del dibujo cuando el estado vale 2
	ld a,005h		;47cb   ; el campo 5 es el parpadeo
	call campo_del_barco		;47cd
	cp 000h		;47d0
	call nz,parpadea		;47d2
	ld a,(0d6d8h)		;47d5
	cp 000h		;47d8
	call nz,alterna_d6d8		;47da
	jp coloca_la_figura		;47dd
pinta_quieto:		; Variante del dibujo cuando el estado vale 0
	ld a,005h		;47e0   ; el campo 5 de la ficha
	call campo_del_barco		;47e2
	cp 000h		;47e5   ; sin parpadeo se alterna la figura
	call z,parpadea		;47e7
	ld a,(0d6d8h)		;47ea   ; y 0xD6D8 va y viene entre las dos posturas
	cp 000h		;47ed
	call z,alterna_d6d8		;47ef
	jp coloca_la_figura		;47f2
L_47F5:
	ld de,00078h		;47f5
	jp L_4724		;47f8
fila_de_cuatro:		; Cuatro piezas de sprite en fila y vuelta al principio
	ld a,006h		;47fb   ; patron base + 6
	call campo_del_barco		;47fd
	call pon_pieza		;4800
	ld a,007h		;4803   ; patron base + 7, tres veces
	call campo_del_barco		;4805
	call pon_pieza		;4808
	call pon_pieza		;480b
	call pon_pieza		;480e
	ld a,(0f87fh)		;4811   ; y la X vuelve 0x20 pixeles atras
	sub 020h		;4814
L_4816:
	ld (0f87fh),a		;4816
	ret			;4819
fila_de_dos:		; Dos piezas de sprite en fila
	ld a,008h		;481a   ; patron base + 8
	call campo_del_barco		;481c
	call pon_pieza		;481f
	call pon_pieza		;4822
	ld a,(0f87fh)		;4825   ; y la X vuelve 0x10 atras
	sub 010h		;4828
	jp L_4816		;482a
remate_de_figura:		; Las piezas sueltas: la cabeza y los brazos
	ld a,(0f87fh)		;482d   ; cinco pixeles a la derecha...
	add a,005h		;4830
	ld (0f87fh),a		;4832
	ld a,(0f880h)		;4835   ; ...y cuatro hacia abajo
	add a,004h		;4838
	ld (0f880h),a		;483a
	ld a,009h		;483d   ; patron base + 9
	call campo_del_barco		;483f
	call pon_pieza		;4842
	ld a,(0f87fh)		;4845   ; ocho pixeles atras
	sub 008h		;4848
	ld (0f87fh),a		;484a
	ld a,00ah		;484d   ; patron base + 10
	call campo_del_barco		;484f
	call pon_pieza		;4852
	ld a,(0f87fh)		;4855   ; un pixel atras
	dec a			;4858
	ld (0f87fh),a		;4859
	ld a,00bh		;485c   ; patron base + 11
	call campo_del_barco		;485e
	call pon_pieza		;4861
	ld a,001h		;4864   ; y el color, del campo 1 de la ficha
	call campo_del_barco		;4866
	ld (0f880h),a		;4869
	inc hl			;486c
	ld a,(hl)			;486d
	jp L_4816		;486e
pieza_suelta:		; Una pieza de sprite y ocho pixeles atras
	ld a,007h		;4871   ; patron base + 7
	call campo_del_barco		;4873
	call pon_pieza		;4876
	ld a,(0f87fh)		;4879   ; ocho pixeles a la izquierda
	sub 008h		;487c
	jp L_4816		;487e
ultima_pieza:		; La ultima pieza de la figura
	ld a,001h		;4881
	call pon_pieza		;4883
	ld a,(0f87fh)		;4886
	sub 008h		;4889
	jp L_4816		;488b
pon_pieza:		; Escribe una entrada de la tabla de atributos: Y, X, patron y color
	ld (0f882h),a		;488e   ; 0xF882 es el numero de patron
	ld a,(0f880h)		;4891   ; la Y del sprite pasa a ser la fila del mapa...
	ld (0f899h),a		;4894
	ld a,(0f87fh)		;4897   ; ...y la X, la columna
	ld (0f89ah),a		;489a
	ld a,001h		;489d   ; el campo 1 de la ficha
	call campo_del_barco		;489f
	ld e,a			;48a2
	ld a,(0f880h)		;48a3
	sub e			;48a6
	cp 004h		;48a7   ; con cuatro de diferencia, se afina medio pixel
	jp z,L_48B9		;48a9
	cp 000h		;48ac
	jp nz,L_48C1		;48ae
	ld a,(0f880h)		;48b1
	bit 2,a		;48b4   ; y con la columna en un multiplo impar de cuatro, tambien
	jp z,L_48C1		;48b6
L_48B9:
	ld a,(0f899h)		;48b9
	add a,004h		;48bc
	ld (0f899h),a		;48be
L_48C1:
	call tipo_de_baldosa		;48c1   ; terreno 3 es pared: la pieza se manda fuera
	cp 003h		;48c4
	jp z,L_48F4		;48c6
	ld a,(0f87fh)		;48c9
L_48CC:
	call escribe_atributo		;48cc   ; Y
	ld a,(0f880h)		;48cf   ; X
	call escribe_atributo		;48d2   ; numero de patron
	ld a,(0f881h)		;48d5   ; color
	call escribe_atributo		;48d8
	ld a,(0f882h)		;48db
	call escribe_atributo		;48de
	ld a,(0f881h)		;48e1   ; el siguiente sprite lleva el patron siguiente
	inc a			;48e4
	ld (0f881h),a		;48e5
	ld a,(0f87fh)		;48e8   ; y va ocho pixeles mas abajo
	add a,008h		;48eb
	ld (0f87fh),a		;48ed
	ld a,(0f882h)		;48f0
	ret			;48f3
L_48F4:
	ld a,0d1h		;48f4   ; 0xD1: fuera de la pantalla por abajo
	jp L_48CC		;48f6
escribe_atributo:		; Un byte a la tabla de atributos y adelante el puntero
	ld hl,(0f885h)		;48f9
	call 0004dh		;48fc   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	ld hl,(0f885h)		;48ff
	inc hl			;4902
	ld (0f885h),hl		;4903
	ret			;4906
patron_base:		; Deja en 0xF881 el patron de partida de la figura
	ld a,004h		;4907   ; desplazamiento 4 respecto del patron de la postura
L_4909:
	ld (0f889h),a		;4909   ; se guarda el desplazamiento pedido
	ld a,003h		;490c
	call campo_del_barco		;490e   ; el campo 3 de la ficha es el estado
	cp 000h		;4911
	ret nz			;4913   ; con estado distinto de cero no se toca el patron
	ld a,(0f889h)		;4914
	ld (0f881h),a		;4917
	ret			;491a
patron_mas_0:		; La figura sin desplazamiento
	xor a			;491b
	jp L_4909		;491c
patron_mas_10:		; Diez patrones mas alla
	ld a,00ah		;491f
	jp L_4909		;4921
patron_mas_8:		; Ocho patrones mas alla
	ld a,008h		;4924
	jp L_4909		;4926
patron_mas_16:		; Dieciseis patrones mas alla
	ld a,010h		;4929
	jp L_4909		;492b
patron_mas_15:		; Quince patrones mas alla
	ld a,00fh		;492e
	jp L_4909		;4930
patron_mas_18:		; Dieciocho patrones mas alla
	ld a,012h		;4933
	jp L_4909		;4935
patron_mas_17:		; Diecisiete patrones mas alla
	ld a,011h		;4938
	jp L_4909		;493a
patron_mas_12:		; Doce patrones mas alla
	ld a,00ch		;493d
	jp L_4909		;493f
pon_sprite:		; Elige el patron de sprite que toca y lo sube a la VRAM
	ld hl,(0f881h)		;4942   ; 0x78 por debajo del patron base
	ld de,00078h		;4945
	add hl,de			;4948
	ex de,hl			;4949
	ld bc,00010h		;494a   ; dieciseis bytes: media figura de 16x16
	ld hl,0aa10h		;494d   ; el sprite de partida
	call 0005ch		;4950   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld a,003h		;4953   ; estado 1: el muñeco esta parado
	call campo_del_barco		;4955
	cp 001h		;4958
	jp z,L_4993		;495a
	ld a,(hl)			;495d
	cp 003h		;495e
	jp z,L_4993		;4960
	ld a,004h		;4963   ; el campo 4 de la ficha es el fotograma del paso
	call campo_del_barco		;4965
	inc a			;4968
	ld (0f883h),a		;4969
	ld hl,0aa10h		;496c   ; los fotogramas van de dieciseis en dieciseis bytes
	ld de,00010h		;496f
L_4972:
	add hl,de			;4972   ; --- salta tantos fotogramas como diga el campo 4 ---
	ld a,(0f883h)		;4973
	dec a			;4976
	ld (0f883h),a		;4977
	cp 000h		;497a
	jp nz,L_4972		;497c
L_497F:
	ld (0f885h),hl		;497f
	ld hl,(0f881h)		;4982
	ld de,00088h		;4985   ; y la otra media figura, 0x10 mas alla
	add hl,de			;4988
	ex de,hl			;4989
	ld hl,(0f885h)		;498a
	ld bc,00010h		;498d
	jp 0005ch		;4990   ; BIOS LDIRVM - Block transfers to VRAM from memory
L_4993:
	ld hl,0aa00h		;4993   ; parado: el sprite de 0xAA00
	jp L_497F		;4996
parpadea:		; Alterna el fotograma de parpadeo y voltea la figura
	ld a,005h		;4999
	call campo_del_barco		;499b
	ld a,(hl)			;499e   ; el campo 5 de la ficha alterna entre 0 y 1
	inc a			;499f
	ld (hl),a			;49a0
	cp 002h		;49a1
	jp nz,L_49A8		;49a3
	xor a			;49a6
	ld (hl),a			;49a7
L_49A8:
	ld hl,(0f87fh)		;49a8   ; la mitad de arriba de la figura
	ld de,000f0h		;49ab
	add hl,de			;49ae
	ld (0f889h),hl		;49af
	ld de,00078h		;49b2
	add hl,de			;49b5
	ex de,hl			;49b6
	ld hl,(0f889h)		;49b7
	call voltea_bits		;49ba   ; y se le da la vuelta a cada byte
	ld a,005h		;49bd
	call campo_del_barco		;49bf
	ld e,a			;49c2
	ld a,(0d6d8h)		;49c3
	cp e			;49c6
	ret z			;49c7
alterna_d6d8:		; 0xD6D8 va y viene entre 0 y 1: el balanceo del muñeco
	ld a,(0d6d8h)		;49c8   ; el byte esta por encima de 0xD300, o sea que sobrevive a la recarga
	inc a			;49cb
	ld (0d6d8h),a		;49cc
	cp 001h		;49cf
	jp z,L_49D8		;49d1
	xor a			;49d4
	ld (0d6d8h),a		;49d5
L_49D8:
	ld hl,0aa10h		;49d8   ; y con el, los sprites de 0xAA10 a 0xAA5F
	ld de,0aa60h		;49db
voltea_bits:		; Invierte el orden de los bits de cada byte entre HL y DE
	xor a			;49de   ; asi se consigue el dibujo mirando al otro lado sin gastar mas bytes
	ld b,a			;49df
	ld a,(hl)			;49e0   ; el byte original
	bit 0,a		;49e1   ; bit 0 del original...
	call nz,bit0_a_bit7		;49e3   ; ...pasa a ser el bit 7 del resultado
	bit 1,a		;49e6
	call nz,L_4A13		;49e8
	bit 2,a		;49eb
	call nz,L_4A16		;49ed
	bit 3,a		;49f0
	call nz,L_4A19		;49f2
	bit 4,a		;49f5
	call nz,L_4A1C		;49f7
	bit 5,a		;49fa
	call nz,L_4A1F		;49fc
	bit 6,a		;49ff
	call nz,L_4A22		;4a01
	bit 7,a		;4a04
	call nz,L_4A25		;4a06
	ld (hl),b			;4a09   ; y el byte volteado se escribe encima
	inc hl			;4a0a
	rst 20h			;4a0b   ; hasta llegar a DE
	jp nz,voltea_bits		;4a0c
	ret			;4a0f
bit0_a_bit7:		; Uno de los ocho pasos del volteo
	set 7,b		;4a10
	ret			;4a12
L_4A13:
	set 6,b		;4a13
	ret			;4a15
L_4A16:
	set 5,b		;4a16
	ret			;4a18
L_4A19:
	set 4,b		;4a19
	ret			;4a1b
L_4A1C:
	set 3,b		;4a1c
	ret			;4a1e
L_4A1F:
	set 2,b		;4a1f
	ret			;4a21
L_4A22:
	set 1,b		;4a22
	ret			;4a24
L_4A25:
	set 0,b		;4a25
	ret			;4a27
pon_sprite_de_brazo:		; El sprite del brazo, que cambia con lo que se lleva
	ld a,004h		;4a28   ; el campo 4 de la ficha
	call campo_del_barco		;4a2a
	cp 000h		;4a2d   ; sin fotograma, no hay brazo
	ret z			;4a2f
	ld (0f883h),a		;4a30
	dec hl			;4a33
	ld a,(hl)			;4a34
	cp 001h		;4a35
	jp z,L_4A6D		;4a37
	ld a,(hl)			;4a3a
	cp 003h		;4a3b
	jp z,L_4A6D		;4a3d
	ld hl,0aa20h		;4a40   ; los brazos empiezan en 0xAA20
	ld de,00010h		;4a43
L_4A46:
	ld a,(0f883h)		;4a46   ; --- salta tantos brazos como diga el campo 4 ---
	cp 000h		;4a49
	jp z,L_4A59		;4a4b
	add hl,de			;4a4e
	ld a,(0f883h)		;4a4f
	dec a			;4a52
	ld (0f883h),a		;4a53
	jp L_4A46		;4a56
L_4A59:
	ld (0f889h),hl		;4a59
	ld hl,(0f881h)		;4a5c
	ld de,00088h		;4a5f   ; 0x88 por debajo del patron base
	add hl,de			;4a62
	ex de,hl			;4a63
	ld hl,(0f889h)		;4a64
	ld bc,00010h		;4a67
	jp 0005ch		;4a6a   ; BIOS LDIRVM - Block transfers to VRAM from memory
L_4A6D:
	ld a,(0f883h)		;4a6d   ; estado 1 o 3: el brazo se lee de la propia pantalla
	cp 002h		;4a70
	ret z			;4a72
	ld a,(0f883h)		;4a73
	cp 001h		;4a76
	jp z,L_4AB3		;4a78
	ld de,00088h		;4a7b
L_4A7E:
	ld hl,(0f881h)		;4a7e   ; se recogen los bytes de la VRAM uno a uno...
	add hl,de			;4a81
	ld (0f885h),hl		;4a82
	ld a,003h		;4a85
	call campo_del_barco		;4a87
	cp 003h		;4a8a
	jp z,L_4AB9		;4a8c
	ld bc,00004h		;4a8f
	ld de,00004h		;4a92
	ld a,004h		;4a95
L_4A97:
	ld (0f883h),a		;4a97
L_4A9A:
	ld hl,(0f885h)		;4a9a
	add hl,de			;4a9d
	call 0004ah		;4a9e   ; BIOS RDVRM - Reads the content of VRAM | ...con RDVRM...
	call escribe_atributo		;4aa1
	ld a,(0f883h)		;4aa4
	dec a			;4aa7
	ld (0f883h),a		;4aa8
	cp 000h		;4aab
	jp nz,L_4A9A		;4aad
	jp 00056h		;4ab0   ; BIOS FILVRM - Fills VRAM with value | ...y se sueltan como color de sprite
L_4AB3:
	ld de,00090h		;4ab3
	jp L_4A7E		;4ab6
L_4AB9:
	ld bc,00003h		;4ab9
	ld de,00002h		;4abc
	ld a,005h		;4abf
	jp L_4A97		;4ac1

; ----------------------------------------------------------------------
; --- el relevo: se cambia de tripulante --------------------
; El jugador no lleva un personaje sino a toda la tripulacion:
; con el gatillo se pasa al siguiente, y el que se deja se
; queda donde estaba con la postura que tuviera. Por eso la
; posicion se guarda en la tabla de 0xB02C antes de soltarlo.
; ----------------------------------------------------------------------
cambia_de_tripulante:		; Con el gatillo, se pasa a llevar a otro
	call lee_gatillo		;4ac4   ; el gatillo
	cp 0ffh		;4ac7
	ret nz			;4ac9
	ld a,(0f89bh)		;4aca   ; trepando no se suelta el mando
	cp 001h		;4acd
	ret z			;4acf
	call 000c0h		;4ad0   ; BIOS BEEP - Generates beep | BEEP
	xor a			;4ad3   ; 0xF8AB, el contador de premios, a cero
	ld (0f8abh),a		;4ad4
	ld a,(0f897h)		;4ad7   ; el numero de tripulante que se deja
	ld e,a			;4ada
	ld a,(0f898h)		;4adb
	add a,e			;4ade
	ld e,a			;4adf
	xor a			;4ae0
	ld d,a			;4ae1
	ld hl,0b02ch		;4ae2   ; su casilla en la tabla de posiciones, cuatro bytes por entrada
	add hl,de			;4ae5
	add hl,de			;4ae6
	add hl,de			;4ae7
	add hl,de			;4ae8
	ld de,(0f88fh)		;4ae9   ; se guardan las dos coordenadas de la ventana
	ld (hl),e			;4aed
	inc hl			;4aee
	ld (hl),d			;4aef
	inc hl			;4af0
	ld (0f881h),hl		;4af1
	ld a,001h		;4af4   ; y las dos de la ficha, la X...
	call campo_del_barco		;4af6
	ld hl,(0f881h)		;4af9
	ld (hl),a			;4afc
	ld a,002h		;4afd   ; ...y la Y
	call campo_del_barco		;4aff
	ld hl,(0f881h)		;4b02
	inc hl			;4b05
	ld (hl),a			;4b06
	ld a,(0f897h)		;4b07   ; con el barco 2 hay que mirar la vela
	cp 002h		;4b0a
	jp z,mira_al_barco_2		;4b0c
	cp 003h		;4b0f   ; y con el 3, el estado de la tripulacion
	jp z,estado_del_tripulante		;4b11
siguiente_barco:		; Pasa al barco siguiente, o al primer tripulante
	ld a,(0f897h)		;4b14
	cp 003h		;4b17   ; el barco 3 es el ultimo
	jp z,siguiente_tripulante_del_3		;4b19
	inc a			;4b1c   ; y si no, uno mas
	ld (0f897h),a		;4b1d
	jp coloca_al_nuevo		;4b20
siguiente_tripulante_del_3:		; Dentro del barco 3, el tripulante siguiente
	ld a,(0f898h)		;4b23   ; 0xF898 recorre la tripulacion
	inc a			;4b26
	ld (0f898h),a		;4b27
	ld e,a			;4b2a
	ld a,(0f39fh)		;4b2b   ; 0xF39F es cuantos son
	cp e			;4b2e
	jp nz,coloca_al_nuevo		;4b2f
	xor a			;4b32   ; al pasar del ultimo se vuelve al barco 0
	ld (0f898h),a		;4b33
	ld (0f897h),a		;4b36
coloca_al_nuevo:		; Recupera la posicion guardada del que toca llevar
	ld a,(0f897h)		;4b39   ; barco mas tripulante da la entrada de la tabla
	ld e,a			;4b3c
	ld a,(0f898h)		;4b3d
	add a,e			;4b40
	ld e,a			;4b41
	xor a			;4b42
	ld d,a			;4b43
	ld hl,0b02ch		;4b44   ; cuatro bytes por entrada
	add hl,de			;4b47
	add hl,de			;4b48
	add hl,de			;4b49
	add hl,de			;4b4a
	ld a,(hl)			;4b4b   ; la columna de la ventana...
	inc hl			;4b4c
	ld (0f88fh),a		;4b4d
	ld a,(hl)			;4b50   ; ...y la fila
	inc hl			;4b51
	ld (0f890h),a		;4b52
	ld (0f899h),hl		;4b55   ; los otros dos bytes son la posicion fina
	call apunta_al_barco		;4b58   ; punteros al dia
	ld a,001h		;4b5b   ; el campo 1 de la ficha: la X
	call campo_del_barco		;4b5d
	ld de,(0f899h)		;4b60
	ld a,(de)			;4b64
	ld (hl),a			;4b65
	ld a,002h		;4b66   ; el campo 2: la Y
	call campo_del_barco		;4b68
	ld de,(0f899h)		;4b6b
	inc de			;4b6f
	ld a,(de)			;4b70
	ld (hl),a			;4b71
	inc hl			;4b72
	ld a,003h		;4b73   ; y el campo 3, el estado, a 3
	ld (hl),a			;4b75
	jp sonido_corto		;4b76   ; con su pitido
primera_pintada:		; Deja el barco y la tripulacion como estan al empezar
	ld a,0ffh		;4b79   ; 0xF8A1 recorre la tripulacion; empieza fuera de rango
	ld (0f8a1h),a		;4b7b
	inc a			;4b7e
	ld (0f8d1h),a		;4b7f   ; 0xF8D1 y 0xF8D2: sin relevo pendiente ni premio
	ld (0f8d2h),a		;4b82
	call pinta_la_carga		;4b85   ; lo que se ha estropeado
	call borra_la_ruta		;4b88   ; la ruta anotada
	call pinta_los_avisos		;4b8b   ; los avisos
	call pinta_barco_0		;4b8e   ; los otros tres barcos
	call pinta_barco_1		;4b91
	call pinta_barco_2		;4b94
	ld hl,0c958h		;4b97   ; la lista de puestos de trabajo
	ld (0f8ach),hl		;4b9a
	call siguiente_tripulante		;4b9d   ; ocho tripulantes, uno por puesto de la lista
	call siguiente_tripulante		;4ba0
	call siguiente_tripulante		;4ba3
	call siguiente_tripulante		;4ba6
	call siguiente_tripulante		;4ba9
	call siguiente_tripulante		;4bac
	call siguiente_tripulante		;4baf
	call siguiente_tripulante		;4bb2
	jp sube_pantalla		;4bb5   ; y se sube todo a la pantalla
pon_en_pantalla:		; Deja en 0xF89F/0xF8A0 la casilla del barco A
	ld e,a			;4bb8   ; el barco pedido
	xor a			;4bb9
	ld d,a			;4bba
	ld hl,0b02ch		;4bbb   ; su ficha, once bytes por barco
	add hl,de			;4bbe
	add hl,de			;4bbf
	add hl,de			;4bc0
	add hl,de			;4bc1
	ld ix,00000h		;4bc2   ; con IX se leen los campos sin tocar HL
	ld d,h			;4bc6
	ld e,l			;4bc7
	add ix,de		;4bc8
	ld a,(ix+002h)		;4bca   ; el campo 3 es la X fina
	add a,004h		;4bcd   ; +4 y dividido entre 8: la columna
	srl a		;4bcf
	srl a		;4bd1
	srl a		;4bd3
	ld e,a			;4bd5
	ld a,(ix+000h)		;4bd6   ; mas el campo 1, que es la columna gruesa
	add a,e			;4bd9
	ld (0f89fh),a		;4bda
	ld a,(ix+003h)		;4bdd   ; y lo mismo con la fila
	add a,004h		;4be0
	srl a		;4be2
	srl a		;4be4
	srl a		;4be6
	ld e,a			;4be8
	ld a,(ix+001h)		;4be9
	add a,e			;4bec
	ld (0f8a0h),a		;4bed
	ret			;4bf0
dibuja_y_baja:		; Pinta la baldosa A y baja una fila
	call pinta_baldosa		;4bf1
baja_una_fila:		; 0xF89F++ : una fila mas abajo en el mapa
	ld hl,0f89fh		;4bf4
	inc (hl)			;4bf7
	ret			;4bf8
dibuja_y_avanza:		; Pinta la baldosa A y avanza una columna
	call pinta_baldosa		;4bf9
avanza_columna:		; 0xF8A0++
	ld hl,0f8a0h		;4bfc
	inc (hl)			;4bff
	ret			;4c00
dibuja_y_retrocede:		; Pinta la baldosa A y retrocede una columna
	call pinta_baldosa		;4c01
retrocede_columna:		; 0xF8A0--
	ld hl,0f8a0h		;4c04
	dec (hl)			;4c07
	ret			;4c08
retrocede:		; 0xF89F-- : una fila mas arriba
	ld hl,0f89fh		;4c09
	dec (hl)			;4c0c
	ret			;4c0d
pinta_barco_0:		; Dibuja el primer barco de la flota si no es el que se lleva
	ld a,(0f897h)		;4c0e   ; el barco 0 no se dibuja si es el que se esta manejando
	cp 000h		;4c11
	ret z			;4c13
	xor a			;4c14
	call pon_en_pantalla		;4c15   ; su casilla
	ld a,0e1h		;4c18   ; y sus cinco baldosas: 0xE1 a 0xE5
	call dibuja_y_avanza		;4c1a
	ld a,0e2h		;4c1d
	call dibuja_y_avanza		;4c1f
	ld a,0e3h		;4c22
	call dibuja_y_avanza		;4c24
	ld a,0e4h		;4c27
	call dibuja_y_avanza		;4c29
	ld a,0e5h		;4c2c
	jp pinta_baldosa		;4c2e
pinta_barco_1:		; Dibuja el segundo barco, con las baldosas 0xE8 a 0xEC
	ld a,(0f897h)		;4c31   ; el barco 1 no se dibuja si es el que se maneja
	cp 001h		;4c34
	ret z			;4c36
	ld a,001h		;4c37   ; su casilla
	call pon_en_pantalla		;4c39
	ld a,0e8h		;4c3c   ; baldosa 0xE8
	call dibuja_y_avanza		;4c3e
	ld a,0e9h		;4c41   ; 0xE9
	call dibuja_y_avanza		;4c43
	ld a,0eah		;4c46   ; 0xEA
	call dibuja_y_avanza		;4c48
	ld a,0ebh		;4c4b   ; 0xEB
	call dibuja_y_avanza		;4c4d
	ld a,0ech		;4c50   ; y 0xEC
	jp pinta_baldosa		;4c52
pinta_barco_2:		; Dibuja el tercer barco, con la vela desplegada
	ld a,(0f897h)		;4c55
	cp 002h		;4c58
	ret z			;4c5a
	ld a,002h		;4c5b
	call pon_en_pantalla		;4c5d
	ld a,0d7h		;4c60   ; baldosas 0xD7, 0xD9 y 0xDD
	call dibuja_y_avanza		;4c62
	ld a,0d9h		;4c65
	call dibuja_y_avanza		;4c67
	ld a,0ddh		;4c6a
	call dibuja_y_avanza		;4c6c
	ld a,(0f8a2h)		;4c6f   ; 0xF8A2 dice si lleva la vela puesta
	cp 000h		;4c72
	call nz,pinta_la_vela		;4c74
	ld a,0efh		;4c77   ; y remata con 0xEF y 0xEC
	call dibuja_y_avanza		;4c79
	ld a,0ech		;4c7c
	jp pinta_baldosa		;4c7e
pinta_la_vela:		; La vela del tercer barco, que ondea
	ld a,(0f8a2h)		;4c81   ; 0xF8A2 alterna entre 1 y 2
	inc a			;4c84
	ld (0f8a2h),a		;4c85
	cp 003h		;4c88
	jp nz,L_4C92		;4c8a
	ld a,001h		;4c8d
	ld (0f8a2h),a		;4c8f
L_4C92:
	call baja_una_fila		;4c92   ; una fila abajo y una columna atras
	call retrocede_columna		;4c95
	ld a,(0f8a2h)		;4c98
	cp 001h		;4c9b
	jp z,L_4CB8		;4c9d
	ld a,0deh		;4ca0   ; la vela hinchada
L_4CA2:
	call dibuja_y_baja		;4ca2   ; baldosa 0xDE o 0xE0, segun toque
	ld a,05ch		;4ca5   ; luego la 0x5C
	call dibuja_y_baja		;4ca7
	ld a,06eh		;4caa   ; y la 0x6E
	call dibuja_y_avanza		;4cac
	call retrocede		;4caf   ; tres columnas atras para dejar el cursor donde estaba
	call retrocede		;4cb2
	jp retrocede		;4cb5
L_4CB8:
	ld a,0e0h		;4cb8   ; o la vela caida
	jp L_4CA2		;4cba
siguiente_tripulante:		; Adelanta el estado de un miembro de la tripulacion
	ld a,(0f39fh)		;4cbd   ; 0xF39F es cuantos son
	ld e,a			;4cc0
	ld a,(0f8a1h)		;4cc1   ; 0xF8A1 va recorriendolos
	inc a			;4cc4
	cp e			;4cc5
	ret z			;4cc6
	ld (0f8a1h),a		;4cc7
	ld e,a			;4cca
	ld a,(0f898h)		;4ccb   ; al que lleva el jugador no se le toca
	cp e			;4cce
	jp nz,L_4CD8		;4ccf
	ld a,(0f897h)		;4cd2
	cp 003h		;4cd5
	ret z			;4cd7
L_4CD8:
	ld a,(0f8a1h)		;4cd8
	ld e,a			;4cdb
	xor a			;4cdc
	ld d,a			;4cdd
	ld hl,0f8a3h		;4cde   ; 0xF8A3 es la tabla de estados, uno por tripulante
	add hl,de			;4ce1
	ld a,(hl)			;4ce2
	and a			;4ce3
	jp z,tripulante_en_puesto		;4ce4   ; estado 0: en su puesto
	cp 001h		;4ce7   ; estado 1
	jp z,tripulante_agachado		;4ce9
	cp 002h		;4cec   ; estado 2
	jp z,tripulante_tirando		;4cee
	cp 003h		;4cf1   ; estado 3
	jp z,tripulante_lejos		;4cf3
	cp 004h		;4cf6   ; estado 4: en un puesto de trabajo de la lista
	jp z,tripulante_en_su_puesto		;4cf8
	cp 005h		;4cfb   ; estado 5
	jp z,tripulante_en_la_vela		;4cfd
	cp 007h		;4d00   ; estado 7: se ha caido
	jp z,tripulante_caido		;4d02
	call casilla_del_tripulante		;4d05
	ld a,0d4h		;4d08   ; y por lo demas, el muñeco de pie
	call dibuja_y_avanza		;4d0a
	ld a,0f1h		;4d0d
	call dibuja_y_avanza		;4d0f
	ld a,0e7h		;4d12
	call dibuja_y_avanza		;4d14
	ld a,0f5h		;4d17
	call dibuja_y_avanza		;4d19
	ld a,0ech		;4d1c
	jp pinta_baldosa		;4d1e
casilla_del_tripulante:		; La casilla del tripulante 0xF8A1
	ld a,(0f8a1h)		;4d21   ; los tres primeros barcos van antes en la tabla de fichas
	add a,003h		;4d24
	jp pon_en_pantalla		;4d26
tripulante_en_puesto:		; El tripulante de pie en su sitio
	call casilla_del_tripulante		;4d29   ; su casilla
	ld a,(0f8a1h)		;4d2c
	add a,003h		;4d2f
	call pon_en_pantalla		;4d31
	call avanza_columna		;4d34   ; una columna a la derecha
	ld a,0d4h		;4d37   ; baldosas 0xD4, 0xF1 y 0xE7: el cuerpo
	call dibuja_y_avanza		;4d39
	ld a,0f1h		;4d3c
	call dibuja_y_avanza		;4d3e
	ld a,0e7h		;4d41
	call dibuja_y_baja		;4d43
	ld a,(0f8b1h)		;4d46   ; 0xF8B1 es el balanceo: cambia la baldosa de los pies
	cp 000h		;4d49
	jp nz,L_4D63		;4d4b
	ld a,0dch		;4d4e   ; 0xDC con un balanceo...
remata_de_pie:		; Las tres baldosas de abajo de la figura de pie
	call dibuja_y_avanza		;4d50
	call retrocede		;4d53   ; una fila arriba
	ld a,0d5h		;4d56   ; baldosa 0xD5
	call pinta_baldosa		;4d58
	call retrocede		;4d5b   ; otra fila arriba
	ld a,0d6h		;4d5e   ; y baldosa 0xD6
	jp pinta_baldosa		;4d60
L_4D63:
	ld a,0dfh		;4d63   ; ...y 0xDF con el otro
	jp remata_de_pie		;4d65
tripulante_agachado:		; El tripulante trabajando agachado
	call casilla_del_tripulante		;4d68   ; su casilla
	call avanza_columna		;4d6b   ; una columna a la derecha
	ld a,0d4h		;4d6e   ; baldosa 0xD4
	call dibuja_y_avanza		;4d70
	ld a,(0f8b1h)		;4d73   ; 0xF8B1 alterna la postura
	cp 000h		;4d76
	jp nz,L_4D9A		;4d78
	ld a,0f1h		;4d7b   ; baldosa 0xF1
	call dibuja_y_baja		;4d7d
	ld a,0dah		;4d80   ; 0xDA y 0xDB: el cuerpo agachado
	call dibuja_y_avanza		;4d82
	call retrocede		;4d85
	ld a,0dbh		;4d88
	call dibuja_y_avanza		;4d8a
remata_agachado:		; Las dos baldosas de arriba, con aviso de relevo
	ld a,0d5h		;4d8d
	call pinta_baldosa		;4d8f
	call retrocede		;4d92
	ld a,0d6h		;4d95
	jp remata_y_avisa		;4d97
L_4D9A:
	ld a,0f1h		;4d9a   ; la variante con la baldosa 0xE7
	call dibuja_y_avanza		;4d9c
	ld a,0e7h		;4d9f
	call dibuja_y_baja		;4da1
	ld a,0d8h		;4da4   ; 0xD8: el brazo estirado
	call dibuja_y_avanza		;4da6
	call retrocede		;4da9
	jp remata_agachado		;4dac
tripulante_tirando:		; El tripulante tirando de un cabo
	call casilla_del_tripulante		;4daf   ; su casilla
	ld a,0d4h		;4db2   ; baldosa 0xD4
	call dibuja_y_avanza		;4db4
	ld a,(0f8b1h)		;4db7   ; 0xF8B1 alterna la postura
	cp 000h		;4dba
	jp nz,L_4DE3		;4dbc
	ld a,0f1h		;4dbf   ; 0xF1 y 0x0A: los brazos en alto
	call dibuja_y_baja		;4dc1
	ld a,00ah		;4dc4
	call dibuja_y_avanza		;4dc6
	call retrocede		;4dc9
	ld a,0e7h		;4dcc   ; 0xE7 y 0xA4
	call dibuja_y_baja		;4dce
	ld a,0a4h		;4dd1
remata_tirando:		; Las tres ultimas baldosas de la figura tirando
	call dibuja_y_avanza		;4dd3
	call retrocede		;4dd6
	ld a,0f5h		;4dd9   ; 0xF5
	call dibuja_y_avanza		;4ddb
	ld a,0ech		;4dde   ; y 0xEC
	jp remata_y_comprueba		;4de0
L_4DE3:
	ld a,032h		;4de3   ; la variante: 0x32, 0xA5 y 0xF5
	call dibuja_y_baja		;4de5
	ld a,0a5h		;4de8
	call dibuja_y_avanza		;4dea
	call retrocede		;4ded
	ld a,0f5h		;4df0
	call dibuja_y_baja		;4df2
	ld a,00dh		;4df5
	jp remata_tirando		;4df7
tripulante_lejos:		; El tripulante cinco columnas mas alla
	call casilla_del_tripulante		;4dfa   ; su casilla
	call baja_una_fila		;4dfd   ; cinco columnas a la derecha
	call baja_una_fila		;4e00
	call baja_una_fila		;4e03
	call baja_una_fila		;4e06
	call baja_una_fila		;4e09
	ld a,0d4h		;4e0c   ; baldosa 0xD4
	call dibuja_y_avanza		;4e0e
	ld a,(0f8b1h)		;4e11   ; 0xF8B1 alterna la postura
	cp 000h		;4e14
	jp nz,L_4E2B		;4e16
	ld a,0f1h		;4e19   ; 0xF1 y 0xE6
	call dibuja_y_baja		;4e1b
	ld a,0e6h		;4e1e
	call dibuja_y_avanza		;4e20
	call retrocede		;4e23
	ld a,0dbh		;4e26
	jp pinta_baldosa		;4e28
L_4E2B:
	ld a,0f1h		;4e2b   ; la variante: 0xF1, 0xE7 y 0xA2
	call dibuja_y_avanza		;4e2d
	ld a,0e7h		;4e30
	call dibuja_y_baja		;4e32
	ld a,0a2h		;4e35
	jp pinta_baldosa		;4e37
tripulante_en_la_vela:		; El tripulante trepado a la verga
	call casilla_del_tripulante		;4e3a   ; su casilla
	call baja_una_fila		;4e3d   ; una fila abajo
	ld a,02ah		;4e40   ; baldosas 0x2A, 0xF2, 0xF4 y 0xF7: los pies en la verga
	call dibuja_y_avanza		;4e42
	ld a,0f2h		;4e45
	call dibuja_y_avanza		;4e47
	ld a,0f4h		;4e4a
	call dibuja_y_avanza		;4e4c
	ld a,0f7h		;4e4f
	call dibuja_y_avanza		;4e51
	ld a,0edh		;4e54   ; 0xED y 0xEE
	call dibuja_y_baja		;4e56
	ld a,0eeh		;4e59
	call dibuja_y_retrocede		;4e5b
	ld a,0f8h		;4e5e   ; y 0xF8, 0xF6, 0xF3 y 0xF0 hacia el otro lado
	call dibuja_y_retrocede		;4e60
	ld a,0f6h		;4e63
	call dibuja_y_retrocede		;4e65
	ld a,0f3h		;4e68
	call dibuja_y_retrocede		;4e6a
	ld a,0f0h		;4e6d
	jp pinta_baldosa		;4e6f
tripulante_en_su_puesto:		; Lo coloca en el puesto de trabajo que toca
	ld hl,(0f8ach)		;4e72   ; 0xF8AC recorre la lista de puestos de 0xC958
	ld a,(hl)			;4e75   ; columna del puesto
	ld (0f89fh),a		;4e76
	inc hl			;4e79
	ld a,(hl)			;4e7a   ; fila del puesto
	ld (0f8a0h),a		;4e7b
	inc hl			;4e7e   ; y el puntero pasa al siguiente
	ld (0f8ach),hl		;4e7f
	call retrocede_columna		;4e82
	ld a,0cdh		;4e85
	call dibuja_y_baja		;4e87
	ld a,0ceh		;4e8a
	call dibuja_y_baja		;4e8c
	ld a,0d0h		;4e8f
	call dibuja_y_baja		;4e91
	ld a,0d2h		;4e94
	call dibuja_y_avanza		;4e96
	ld a,0d1h		;4e99
	call dibuja_y_baja		;4e9b
	ld a,0d3h		;4e9e
	call pinta_baldosa		;4ea0
	call retrocede		;4ea3
	call retrocede		;4ea6
	call retrocede		;4ea9
	call retrocede		;4eac
	ld a,0cbh		;4eaf
	call dibuja_y_baja		;4eb1
	ld a,0cch		;4eb4
	call dibuja_y_baja		;4eb6
	ld a,0cfh		;4eb9
	jp pinta_baldosa		;4ebb
tripulante_caido:		; El tripulante tumbado: ha caido enfermo
	call casilla_del_tripulante		;4ebe   ; su casilla
	ld a,0d4h		;4ec1   ; baldosas 0xD4, 0xF1, 0xE7, 0xF5 y 0xEC
	call dibuja_y_avanza		;4ec3
	ld a,0f1h		;4ec6
	call dibuja_y_avanza		;4ec8
	ld a,0e7h		;4ecb
	call dibuja_y_avanza		;4ecd
	ld a,0f5h		;4ed0
	call dibuja_y_avanza		;4ed2
	ld a,0ech		;4ed5
	call dibuja_y_baja		;4ed7
	call retrocede_columna		;4eda   ; una columna atras y una fila arriba
	ld a,0a0h		;4edd   ; 0xA0: la cabeza tumbada
	call dibuja_y_retrocede		;4edf
	ld a,(0f8b1h)		;4ee2   ; 0xF8B1 le cambia la postura
	and a			;4ee5
	jp z,L_4EFB		;4ee6
	ld a,0dfh		;4ee9   ; 0xDF y dos veces 0x73
	call dibuja_y_avanza		;4eeb
	call baja_una_fila		;4eee
	ld a,073h		;4ef1
	call dibuja_y_avanza		;4ef3
	ld a,073h		;4ef6
	jp L_4EFD		;4ef8
L_4EFB:
	ld a,0dch		;4efb   ; o la 0xDC, la mas quieta
L_4EFD:
	call pinta_baldosa		;4efd
	ld a,(0f8d2h)		;4f00   ; 0xF8D2 marca que hay alguien caido
	and a			;4f03
	ret z			;4f04
	ld a,(0f8b3h)		;4f05   ; 0xF8B3: solo con el efecto 1 se pide relevo
	cp 001h		;4f08
	ret nz			;4f0a
	ld (0f8d1h),a		;4f0b
	ret			;4f0e
remata_y_avisa:		; Pinta la ultima baldosa y avisa si hay que sustituirle
	call pinta_baldosa		;4f0f
	ld a,(0f8d2h)		;4f12   ; 0xF8D2: hay premio pendiente
	and a			;4f15
	ret z			;4f16
	ld a,(0f8b3h)		;4f17   ; y con el efecto 2, se pide relevo
	cp 002h		;4f1a
	ret nz			;4f1c
	dec a			;4f1d
	ld (0f8d1h),a		;4f1e
	ret			;4f21
remata_y_comprueba:		; Pinta y mira si el tripulante esta en un sitio clave
	call pinta_baldosa		;4f22
	call retrocede_columna		;4f25
	call retrocede_columna		;4f28
	call retrocede_columna		;4f2b
	call retrocede_columna		;4f2e
	ld hl,(0f89fh)		;4f31   ; 0x0E09 y 0x1E31: dos casillas del barco que hay que vigilar
	ld de,00e09h		;4f34
	rst 20h			;4f37
	jp z,L_4F4E		;4f38
	ld de,01e31h		;4f3b
	rst 20h			;4f3e
	jp z,L_4F57		;4f3f
	ld a,(0f8b9h)		;4f42   ; 0xF8B9 es el desastre en curso
	cp 00bh		;4f45
	ret nz			;4f47
pide_relevo:		; 0xF8D1 a 1: hace falta que alguien acuda
	ld a,001h		;4f48
	ld (0f8d1h),a		;4f4a
	ret			;4f4d
L_4F4E:
	ld a,(0f8b9h)		;4f4e
	cp 009h		;4f51
	ret nz			;4f53
	jp pide_relevo		;4f54
L_4F57:
	ld a,(0f8b9h)		;4f57
	cp 00ah		;4f5a
	ret nz			;4f5c
	jp pide_relevo		;4f5d

; ----------------------------------------------------------------------
; --- la carga estibada en la bodega ----------------------
; Lo que se compro en el almacen de la primera parte no es solo
; un numero: se DIBUJA en la bodega, un monton por mercancia y
; tantas piezas como unidades queden. Dibujadas, las baldosas
; de cada monton son toneles de duelas, sacos atados, tablones
; apilados y rollos de tela.
; ----------------------------------------------------------------------
pinta_la_carga:		; Dibuja en la bodega lo que se lleva a bordo
	ld hl,02b2ah		;4f60   ; 0x2B2A: la casilla desde la que se estiba
	ld (0f89fh),hl		;4f63
	ld a,(0f39ah)		;4f66   ; los seis bytes que dejo la primera parte: lo comprado alli
	ld e,a			;4f69
	ld a,(0f39bh)		;4f6a
	add a,e			;4f6d
	ld (0f8ach),a		;4f6e
	and a			;4f71
	call nz,pinta_toneles		;4f72   ; AGUA mas VINO: los toneles
	ld a,(0f39eh)		;4f75
	ld (0f8ach),a		;4f78
	and a			;4f7b
	call nz,pinta_sacos		;4f7c   ; la COMIDA: los sacos
	ld a,(0f39ch)		;4f7f
	ld (0f8ach),a		;4f82
	and a			;4f85
	call nz,pinta_tablones		;4f86   ; la MADERA: los tablones
	ld a,(0f39dh)		;4f89
	ld (0f8ach),a		;4f8c
	and a			;4f8f
	jp nz,pinta_rollos		;4f90   ; y la TELA: los rollos
	ret			;4f93
pinta_toneles:		; La fila de toneles de bebida, tantos como diga 0xF8AC
	ld a,0bfh		;4f94   ; baldosas 0xBF a 0xC4: las duelas de un tonel
	call dibuja_y_avanza		;4f96
	ld a,0c0h		;4f99
	call dibuja_y_avanza		;4f9b
	ld a,0c1h		;4f9e
	call dibuja_y_baja		;4fa0
	ld a,0c4h		;4fa3
	call dibuja_y_retrocede		;4fa5
	ld a,0c3h		;4fa8
	call dibuja_y_retrocede		;4faa
	ld a,0c2h		;4fad
	call dibuja_y_baja		;4faf
	call queda_uno_menos		;4fb2   ; y otra fila mas mientras queden
	and a			;4fb5
	jp nz,pinta_toneles		;4fb6
	ret			;4fb9
queda_uno_menos:		; 0xF8AC-- y devuelve lo que queda
	ld hl,0f8ach		;4fba
	dec (hl)			;4fbd
	ld a,(hl)			;4fbe
	ret			;4fbf
pinta_tablones:		; El monton de madera
	call retrocede_columna		;4fc0   ; tres columnas atras
	call retrocede_columna		;4fc3
	call retrocede_columna		;4fc6
	ld a,0c6h		;4fc9   ; baldosas 0xC6, 0xC7 (cuatro veces) y 0xC8
	call dibuja_y_avanza		;4fcb
	ld a,0c7h		;4fce
	call dibuja_y_avanza		;4fd0
	ld a,0c7h		;4fd3
	call dibuja_y_avanza		;4fd5
	ld a,0c7h		;4fd8
	call dibuja_y_avanza		;4fda
	ld a,0c7h		;4fdd
	call dibuja_y_avanza		;4fdf
	ld a,0c8h		;4fe2
	call dibuja_y_baja		;4fe4
	call retrocede_columna		;4fe7   ; y dos columnas atras para la fila siguiente
	call retrocede_columna		;4fea
	call queda_uno_menos		;4fed   ; mientras quede madera
	and a			;4ff0
	jp nz,pinta_tablones		;4ff1
	ret			;4ff4
pinta_rollos:		; Los rollos de tela
	call retrocede_columna		;4ff5   ; tres columnas atras
	call retrocede_columna		;4ff8
	call retrocede_columna		;4ffb
	ld a,0c5h		;4ffe   ; baldosas 0xC5, 0xC9 (cuatro veces) y 0xCA
	call dibuja_y_avanza		;5000
	ld a,0c9h		;5003
	call dibuja_y_avanza		;5005
	ld a,0c9h		;5008
	call dibuja_y_avanza		;500a
	ld a,0c9h		;500d
	call dibuja_y_avanza		;500f
	ld a,0c9h		;5012
	call dibuja_y_avanza		;5014
	ld a,0cah		;5017
	call dibuja_y_baja		;5019
	call retrocede_columna		;501c   ; y dos columnas atras
	call retrocede_columna		;501f
	call queda_uno_menos		;5022   ; mientras quede tela
	and a			;5025
	jp nz,pinta_rollos		;5026
	ret			;5029
pinta_sacos:		; Los sacos de comida
	ld a,0b9h		;502a   ; baldosas 0xB9 a 0xBE: el saco con su cuerda
	call dibuja_y_avanza		;502c
	ld a,0bah		;502f
	call dibuja_y_avanza		;5031
	ld a,0bbh		;5034
	call dibuja_y_baja		;5036   ; dos columnas atras
	ld a,0beh		;5039
	call dibuja_y_retrocede		;503b
	ld a,0bdh		;503e
	call dibuja_y_retrocede		;5040
	ld a,0bch		;5043
	call dibuja_y_baja		;5045   ; y otras dos hacia delante
	call queda_uno_menos		;5048   ; mientras quede comida
	and a			;504b
	jp nz,pinta_sacos		;504c
	ret			;504f
pinta_baldosa:		; Escribe la baldosa A en la copia de la pantalla, si cabe y si se puede
	ld (0f87fh),a		;5050   ; la baldosa que hay que poner
	ld a,(0f88fh)		;5053   ; la columna, en coordenadas del mapa...
	ld e,a			;5056
	ld a,(0f89fh)		;5057
	sub e			;505a   ; ...menos el scroll, da la columna de la pantalla
	cp 020h		;505b   ; fuera de las 32 columnas visibles, no se pinta
	ret nc			;505d
	ld (0f89dh),a		;505e
	ld a,(0f890h)		;5061   ; lo mismo con la fila
	ld e,a			;5064
	ld a,(0f8a0h)		;5065
	sub e			;5068
	cp 018h		;5069   ; ni fuera de las 24 filas
	ret nc			;506b
	ld (0f89eh),a		;506c
	ld a,(0f89dh)		;506f
	ld e,a			;5072
	xor a			;5073
	ld d,a			;5074
	ld hl,0b058h		;5075   ; 0xB058 es la copia de la tabla de nombres
	add hl,de			;5078
	ld a,(0f89eh)		;5079
	ld de,00020h		;507c   ; y cada fila son 0x20 baldosas
L_507F:
	cp 000h		;507f
	jp z,L_5089		;5081
	add hl,de			;5084
	dec a			;5085
	jp L_507F		;5086
L_5089:
	ld a,(hl)			;5089   ; lo que hay puesto ahora
	cp 0fbh		;508a   ; 0xFB, 0xFC, 0xF9 y 0xFA: las que dan puntos
	jp z,marca_bonus		;508c
	cp 0fch		;508f
	jp z,marca_bonus		;5091
	cp 0f9h		;5094
	jp z,marca_bonus		;5096
	cp 0fah		;5099
	jp z,marca_bonus		;509b
	cp 034h		;509e   ; 0x34, 0x27, 0x1B, 0x33 y 0x31: borda, cubierta, escalera y mastil
	ret z			;50a0
	cp 027h		;50a1
	ret z			;50a3
	cp 01bh		;50a4
	ret z			;50a6
	cp 033h		;50a7
	ret z			;50a9
	cp 031h		;50aa
	ret z			;50ac
	cp 0a3h		;50ad   ; 0xA3, 0x91, 0x5F, 0x0C, 0x6D, 0x4A y 0xB8: los mamparos
	ret z			;50af
	cp 091h		;50b0
	ret z			;50b2
	cp 05fh		;50b3
	ret z			;50b5
	cp 00ch		;50b6
	ret z			;50b8
	cp 06dh		;50b9
	ret z			;50bb
	cp 04ah		;50bc
	ret z			;50be
	cp 0b8h		;50bf   ; y hay baldosas que no se pisan: se dejan como estan
	ret z			;50c1
L_50C2:
	ld a,(0f87fh)		;50c2   ; lo demas se puede pisar y se pinta
	ld (hl),a			;50c5
	ret			;50c6
sube_pantalla:		; Sube de golpe la copia de 0xB058 a la tabla de nombres
	ld hl,0b058h		;50c7
	ld de,01800h		;50ca
	ld bc,00300h		;50cd   ; 0x300 bytes: 32 por 24
	call 0005ch		;50d0   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ei			;50d3   ; y ya se pueden abrir las interrupciones
	ret			;50d4
marca_bonus:		; Anota en 0xF8D2 que se ha pisado una baldosa de premio
	ld a,001h		;50d5
	ld (0f8d2h),a		;50d7
	jp L_50C2		;50da
mira_al_barco_2:		; El tercer barco tiene la vela puesta si esta en 0x1B0A
	ld a,002h		;50dd   ; la casilla del barco 2
	call pon_en_pantalla		;50df
	ld de,01b0ah		;50e2   ; 0x1B0A: la casilla donde le da el viento
	ld hl,(0f89fh)		;50e5
	rst 20h			;50e8
	jp nz,L_50F4		;50e9
	ld a,001h		;50ec   ; 1 con la vela puesta, 0 sin ella
L_50EE:
	ld (0f8a2h),a		;50ee
	jp siguiente_barco		;50f1
L_50F4:
	xor a			;50f4
	jp L_50EE		;50f5
estado_del_tripulante:		; Decide en que estado queda cada tripulante
	ld a,(0f898h)		;50f8
	ld e,a			;50fb
	ld a,(0f8c8h)		;50fc   ; 0xF8C8 dice si hay una orden en marcha...
	and a			;50ff
	jp z,L_510A		;5100
	ld a,(0f8c0h)		;5103   ; ...y para quien
	cp e			;5106
	jp z,siguiente_tripulante_del_3		;5107
L_510A:
	ld a,(0f8cbh)		;510a   ; 0xF8CB, la segunda orden
	and a			;510d
	jp z,L_5118		;510e
	ld a,(0f8c1h)		;5111
	cp e			;5114
	jp z,siguiente_tripulante_del_3		;5115
L_5118:
	ld a,(0f898h)		;5118
	ld e,a			;511b
	xor a			;511c
	ld d,a			;511d
	ld hl,0f8d6h		;511e   ; 0xF8D6 es el cansancio de cada tripulante
	add hl,de			;5121
	ld a,(hl)			;5122
	cp 003h		;5123   ; con 3 esta agotado
	jp z,L_51A2		;5125
	ld a,(0f8c8h)		;5128
	and a			;512b
	jp z,L_513A		;512c
	ld a,(0f898h)		;512f
	ld e,a			;5132
	ld a,(0f8c0h)		;5133
	cp e			;5136
	jp z,estado_7		;5137
L_513A:
	ld a,(0f8cbh)		;513a   ; 0xF8CB: la segunda orden
	and a			;513d
	jp z,L_514C		;513e
	ld a,(0f898h)		;5141   ; y a quien va dirigida
	ld e,a			;5144
	ld a,(0f8c1h)		;5145
	cp e			;5148
	jp z,estado_7		;5149
L_514C:
	ld a,(0f898h)		;514c   ; --- el tripulante no tiene orden pendiente ---
	add a,003h		;514f
	call pon_en_pantalla		;5151
	ld de,00b0fh		;5154   ; 0x0B0F, 0x2963, 0x0E09, 0x1E31 y 0x1E51: los puestos del barco
	ld hl,(0f89fh)		;5157
	rst 20h			;515a
	jp z,estado_5		;515b
	ld de,02963h		;515e
	rst 20h			;5161
	jp z,estado_3		;5162
	ld de,00e09h		;5165
	rst 20h			;5168
	jp z,estado_2		;5169
	ld de,01e31h		;516c
	rst 20h			;516f
	jp z,estado_2		;5170
	ld de,01e51h		;5173
	rst 20h			;5176
	jp z,estado_2		;5177
	ld a,(0f8a0h)		;517a   ; fila 0x29, entre las columnas 9 y 0x1F: la cubierta
	cp 029h		;517d
	jp nz,L_5197		;517f
	ld a,(0f89fh)		;5182
	cp 009h		;5185
	jp c,L_5197		;5187
	cp 01fh		;518a
	jp nc,L_5197		;518c
L_518F:
	call estado_de		;518f   ; pasa al estado 4: en su puesto de trabajo
	ld a,004h		;5192
	jp L_51D2		;5194
L_5197:
	ld a,(0f8a0h)		;5197   ; por debajo de la fila 0x28 esta arriba
	cp 028h		;519a
	jp c,estado_0		;519c
	jp estado_1		;519f
L_51A2:
	ld a,(0f898h)		;51a2   ; --- el tripulante esta agotado (cansancio 3) ---
	add a,003h		;51a5
	call pon_en_pantalla		;51a7
	ld a,(0f8a0h)		;51aa   ; su casilla
	cp 029h		;51ad   ; fila 0x29, columnas 9 a 0x1F
	jp nz,estado_6		;51af
	ld a,(0f89fh)		;51b2
	cp 009h		;51b5
	jp c,estado_6		;51b7
	cp 01fh		;51ba
	jp nc,estado_6		;51bc
	jp L_518F		;51bf   ; y si no, estado 6
estado_de:		; Apunta a la casilla de estado del tripulante 0xF898
	ld a,(0f898h)		;51c2   ; el tripulante en curso
	ld e,a			;51c5
	xor a			;51c6
	ld d,a			;51c7
	ld hl,0f8a3h		;51c8   ; 0xF8A3 es la tabla de estados, uno por tripulante
	add hl,de			;51cb
	ret			;51cc
estado_5:		; El tripulante pasa al estado 5
	call estado_de		;51cd
	ld a,005h		;51d0
L_51D2:
	ld (hl),a			;51d2
	jp siguiente_tripulante_del_3		;51d3
estado_3:		; El tripulante pasa al estado 3
	call estado_de		;51d6
	ld a,003h		;51d9
	jp L_51D2		;51db
estado_2:		; Con fuego declarado, el tripulante pasa al estado 2
	ld a,(0f39dh)		;51de   ; 0xF39D es la TELA que queda
	and a			;51e1
	jp z,estado_0		;51e2   ; sin tela no se puede sofocar el fuego: el tripulante vuelve a su puesto
	call estado_de		;51e5
	ld a,002h		;51e8
	jp L_51D2		;51ea
estado_0:		; El tripulante vuelve a su puesto
	call estado_de		;51ed
	xor a			;51f0
	jp L_51D2		;51f1
estado_1:		; Con via de agua, el tripulante pasa al estado 1
	ld a,(0f39ch)		;51f4   ; 0xF39C es la MADERA que queda
	and a			;51f7
	jp z,estado_0		;51f8   ; sin madera no se tapa la via de agua: vuelve a su puesto
	call estado_de		;51fb
	ld a,001h		;51fe
	jp L_51D2		;5200
estado_7:		; El tripulante se cae
	call estado_de		;5203
	ld a,007h		;5206
	jp L_51D2		;5208
estado_6:		; El tripulante pasa al estado 6
	call estado_de		;520b
	ld a,006h		;520e
	jp L_51D2		;5210
sonido_corto:		; Cinco registros del PSG: el pitido de aviso
	ld a,006h		;5213   ; registros 6, 7 y 8: ruido, mezcla y volumen
	ld e,014h		;5215
	call 00093h		;5217   ; BIOS WRTPSG - Writes data to PSG-register
	inc a			;521a
	ld e,037h		;521b
	call 00093h		;521d   ; BIOS WRTPSG - Writes data to PSG-register
	inc a			;5220
	ld e,010h		;5221
	call 00093h		;5223   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00ch		;5226   ; registros 12 y 13: el envolvente
	ld e,050h		;5228
	call 00093h		;522a   ; BIOS WRTPSG - Writes data to PSG-register
	inc a			;522d
	ld e,00eh		;522e
	jp 00093h		;5230   ; BIOS WRTPSG - Writes data to PSG-register
pasa_el_tiempo:		; Un dia cada 60 vueltas del contador de 0xF8BD
	ld hl,(0f8bdh)		;5233   ; 0xF8BD cuenta las vueltas
	inc hl			;5236
	ld (0f8bdh),hl		;5237
	ld de,0003ch		;523a   ; 0x3C = 60 vueltas
	rst 20h			;523d
	ret nz			;523e
	ld hl,00000h		;523f
	ld (0f8bdh),hl		;5242
	ld a,(0f8bch)		;5245   ; 0xF8BC es la hora del dia, de 0 a 15
	inc a			;5248
	ld (0f8bch),a		;5249
	cp 010h		;524c
	ret nz			;524e
	xor a			;524f
	ld (0f8bch),a		;5250
	call cuenta_dia		;5253   ; se cuenta un dia mas
	call desgasta_tripulacion		;5256   ; se cansa a la tripulacion
	call desanima		;5259   ; se gastan las provisiones
	call gasta_provisiones		;525c
	call penaliza		;525f
	ld a,(0f8bbh)		;5262   ; 0xF8BB es cuanto queda para que el barco se mueva
	dec a			;5265
	ld (0f8bbh),a		;5266
	and a			;5269
	ret nz			;526a
	ld a,(0f8bfh)		;526b   ; 0xF8BF es el rumbo: 0 poniente, 1 levante, 2 norte, 3 sur
	and a			;526e
	jp z,rumbo_poniente		;526f
	cp 001h		;5272
	jp z,rumbo_norte		;5274
	cp 002h		;5277
	jp z,rumbo_levante		;5279
	jp rumbo_sur		;527c
casilla_del_oceano:		; Lee la casilla (0xF8B7, 0xF8B8) de la carta de 20x20
	ld a,(0f8b7h)		;527f   ; 0xF8B7 es la columna
	ld e,a			;5282
	xor a			;5283
	ld d,a			;5284
	ld hl,0c98ch		;5285   ; 0xC98C es la carta
	add hl,de			;5288
	ld de,00014h		;5289   ; y cada fila son 0x14 = 20 casillas
	ld a,(0f8b8h)		;528c   ; 0xF8B8 es la fila
L_528F:
	and a			;528f   ; --- baja tantas filas como haga falta ---
	jp z,L_5298		;5290
	dec a			;5293
	add hl,de			;5294
	jp L_528F		;5295
L_5298:
	ld a,(hl)			;5298   ; y el valor de la casilla queda en 0xF8B9
	ld (0f8b9h),a		;5299
aplica_casilla:		; Segun lo que haya en la casilla, decide que pasa
	xor a			;529c
	ld (0f8b3h),a		;529d   ; 0xF8B3 es el efecto en curso
	ld (0f8dfh),a		;52a0
	ld a,(0f8b9h)		;52a3   ; el valor de la casilla
	and a			;52a6
	jp z,tres_de_avance		;52a7   ; 0: mar abierto
	cp 001h		;52aa   ; 1: corriente a favor
	jp z,uno_de_avance		;52ac
	cp 002h		;52af   ; 2: corriente en contra
	jp z,dos_de_avance		;52b1
	call uno_de_avance		;52b4   ; y de 3 en adelante, un contratiempo
	ld a,001h		;52b7
	ld (0f8dfh),a		;52b9
	ld a,(0f8b9h)		;52bc
	sub 003h		;52bf   ; los efectos se indexan por el valor menos 3
	ld e,a			;52c1
	xor a			;52c2
	ld d,a			;52c3
	ld hl,0c968h		;52c4   ; la tabla de efectos, de cuatro bytes por entrada
	add hl,de			;52c7
	add hl,de			;52c8
	add hl,de			;52c9
	add hl,de			;52ca
	ld de,0f8b3h		;52cb   ; se copian a 0xF8B3-0xF8B6
	call copia_byte		;52ce
	call copia_byte		;52d1
	call copia_byte		;52d4
	call copia_byte		;52d7
	ld hl,0cb1eh		;52da   ; la ruta se empieza a anotar en 0xCB1E
	ld (0f8afh),hl		;52dd
	ld hl,(0f8b5h)		;52e0   ; y el punto de partida, en 0xCB1C
	ld (0cb1ch),hl		;52e3
	ret			;52e6
tres_de_avance:		; Con mar abierto, el barco avanza tres
	ld a,003h		;52e7
	ld (0f8bbh),a		;52e9
	ret			;52ec
uno_de_avance:		; Con corriente a favor, avanza uno
	ld a,001h		;52ed
	ld (0f8bbh),a		;52ef
	ret			;52f2
dos_de_avance:		; Con corriente en contra, avanza dos
	ld a,002h		;52f3
	ld (0f8bbh),a		;52f5
	ret			;52f8
rumbo_poniente:		; Una casilla hacia poniente
	ld a,(0f8b7h)		;52f9   ; en la columna 0 ya no se puede ir mas
	and a			;52fc
	jp z,fin_del_mundo		;52fd
	dec a			;5300
L_5301:
	ld (0f8b7h),a		;5301
	jp casilla_del_oceano		;5304
rumbo_levante:		; Una casilla hacia levante
	ld a,(0f8b7h)		;5307
	cp 013h		;530a   ; 0x13 es la ultima columna de la carta
	jp z,casilla_del_oceano		;530c
	inc a			;530f
	jp L_5301		;5310
rumbo_norte:		; Una casilla hacia el norte
	ld a,(0f8b8h)		;5313
	and a			;5316
	jp z,casilla_del_oceano		;5317
	dec a			;531a
L_531B:
	ld (0f8b8h),a		;531b
	jp casilla_del_oceano		;531e
rumbo_sur:		; Una casilla hacia el sur
	ld a,(0f8b8h)		;5321
	cp 013h		;5324   ; 0x13 es la ultima fila
	jp z,casilla_del_oceano		;5326
	inc a			;5329
	jp L_531B		;532a
copia_byte:		; Un byte de (HL) a (DE) y adelante los dos
	ld a,(hl)			;532d
	ld (de),a			;532e
	inc hl			;532f
	inc de			;5330
	ret			;5331
fin_del_mundo:		; Al llegar al borde de poniente, se acabo la travesia
	ld a,0ffh		;5332   ; 0xFF en 0xF8DE: el desenlace
	ld (0f8deh),a		;5334
	call marca_ruta_en_carta		;5337
	jp casilla_del_oceano		;533a
avanza_la_ruta:		; Va marcando en la carta el rastro del barco
	ld hl,(0f8bdh)		;533d   ; con el reloj a media vuelta no se anota nada
	ld de,00000h		;5340
	rst 20h			;5343
	ret nz			;5344
	ld a,(0f8b3h)		;5345   ; 0xF8B3 es el efecto: sin efecto, se reinicia la ruta
	and a			;5348
	jp z,reinicia_la_ruta		;5349
	ld a,(0f8b3h)		;534c   ; efecto 1
	cp 001h		;534f
	jp z,pasos_efecto_1		;5351
	cp 002h		;5354   ; efecto 2
	jp z,pasos_efecto_2		;5356
	cp 003h		;5359   ; efecto 3
	jp z,pasos_efecto_3		;535b
	ret			;535e
anota_los_puntos:		; Recorre la ruta anotada y va marcando por donde pasa
	di			;535f   ; con la interrupcion cerrada
	ld hl,(0f8afh)		;5360
	ld (0f8ach),hl		;5363
	ld de,00028h		;5366   ; 0x28: veinte puntos de ruta
	add hl,de			;5369
	ld (0f883h),hl		;536a
	ld de,0cb1ch		;536d   ; 0xCB1C es la lista de puntos
	ld (0f88dh),de		;5370
L_5374:
	ld a,(de)			;5374   ; --- un punto por vuelta ---
	inc a			;5375   ; una columna a la derecha
	ld (0f87fh),a		;5376
	inc de			;5379
	ld a,(de)			;537a
	ld (0f880h),a		;537b
	inc de			;537e
	ld (0f88dh),de		;537f
	call punto_de_ruta		;5383
	ld de,(0f8ach)		;5386
	ld hl,(0f883h)		;538a
	rst 20h			;538d
	jp z,L_53D8		;538e
	ld hl,0f87fh		;5391   ; si no, una fila abajo
	dec (hl)			;5394
	inc hl			;5395
	inc (hl)			;5396
	call punto_de_ruta		;5397
	ld de,(0f8ach)		;539a
	ld hl,(0f883h)		;539e
	rst 20h			;53a1
	jp z,L_53D8		;53a2
	ld hl,0f87fh		;53a5   ; o una fila arriba
	dec (hl)			;53a8
	inc hl			;53a9
	dec (hl)			;53aa
	call punto_de_ruta		;53ab
	ld de,(0f8ach)		;53ae
	ld hl,(0f883h)		;53b2
	rst 20h			;53b5
	jp z,L_53D8		;53b6
	ld hl,0f87fh		;53b9   ; o una columna a la izquierda
	inc (hl)			;53bc
	inc hl			;53bd
	dec (hl)			;53be
	call punto_de_ruta		;53bf
	ld de,(0f8ach)		;53c2
	ld hl,(0f883h)		;53c6
	rst 20h			;53c9
	jp z,L_53D8		;53ca
	ld hl,(0f8ach)		;53cd   ; hasta agotar la lista
	ld de,(0f88dh)		;53d0
	rst 20h			;53d4
	jp nz,L_5374		;53d5
L_53D8:
	ld hl,(0f8ach)		;53d8
	ld (0f8afh),hl		;53db
	ei			;53de
	ret			;53df
pasos_efecto_1:		; El efecto 1 se nota a las horas 7, 8 y 9
	ld a,(0f8bch)		;53e0   ; 0xF8BC es la hora del dia
	cp 007h		;53e3   ; hora 7
	jp z,anota_los_puntos		;53e5
	cp 008h		;53e8   ; hora 8
	jp z,anota_los_puntos		;53ea
	cp 009h		;53ed   ; hora 9
	jp z,anota_los_puntos		;53ef
	ret			;53f2
pasos_efecto_2:		; El efecto 2 se nota a las horas 4, 5 y 6
	ld a,(0f8bch)		;53f3   ; 0xF8BC es la hora del dia
	cp 004h		;53f6   ; hora 4
	jp z,anota_los_puntos		;53f8
	cp 005h		;53fb   ; hora 5
	jp z,anota_los_puntos		;53fd
	cp 006h		;5400   ; hora 6
	jp z,anota_los_puntos		;5402
	ret			;5405
pasos_efecto_3:		; El efecto 3 se nota a las horas 5, 8 y 11
	ld a,(0f8bch)		;5406   ; 0xF8BC es la hora del dia
	cp 005h		;5409   ; hora 5
	jp z,anota_los_puntos		;540b
	cp 008h		;540e   ; hora 8
	jp z,anota_los_puntos		;5410
	cp 00bh		;5413   ; hora 11
	jp z,anota_los_puntos		;5415
	ret			;5418
punto_de_ruta:		; Anota un punto nuevo de la ruta si la baldosa lo permite
	ld a,(0f87fh)		;5419
	cp 0ffh		;541c   ; 0xFF marca el final de la lista
	ret z			;541e
	ld a,(0f880h)		;541f   ; 0x34 es la borda: por ahi no se pasa
	cp 034h		;5422
	ret z			;5424
	ld hl,0cb1ch		;5425   ; la lista de puntos ya anotados
	ld (0f881h),hl		;5428
L_542B:
	ld e,(hl)			;542b   ; --- mira si el punto ya estaba ---
	inc hl			;542c
	ld d,(hl)			;542d
	inc hl			;542e
	ld (0f881h),hl		;542f
	ld hl,(0f87fh)		;5432
	rst 20h			;5435
	ret z			;5436
	ld de,(0f8ach)		;5437
	ld hl,(0f881h)		;543b
	rst 20h			;543e
	jp nz,L_542B		;543f
	ld hl,09000h		;5442   ; el mapa del barco
	ld a,(0f87fh)		;5445
	ld e,a			;5448
	xor a			;5449
	ld d,a			;544a
	add hl,de			;544b
	ld de,00080h		;544c   ; y cada fila son 0x80 baldosas
	ld a,(0f880h)		;544f
L_5452:
	and a			;5452
	jp z,L_545B		;5453
	dec a			;5456
	add hl,de			;5457
	jp L_5452		;5458
L_545B:
	ld a,(hl)			;545b
	ld (0f885h),a		;545c
	ld a,(0f8b3h)		;545f   ; el efecto en curso decide que baldosas valen
	cp 001h		;5462
	jp z,baldosas_de_paso		;5464   ; efectos 1 y 2
	cp 002h		;5467
	jp z,baldosas_de_paso		;5469
	cp 003h		;546c   ; efecto 3
	jp z,baldosa_de_escala		;546e
	ret			;5471
anota:		; Mete el punto en la lista y adelanta el puntero
	ld hl,(0f8ach)		;5472   ; el final de la lista
	ld a,(0f87fh)		;5475   ; la columna...
	ld (hl),a			;5478
	inc hl			;5479
	ld a,(0f880h)		;547a   ; ...y la fila
	ld (hl),a			;547d
	inc hl			;547e
	ld (0f8ach),hl		;547f   ; dos bytes por punto
	ret			;5482
baldosas_de_paso:		; Las diecinueve baldosas por las que puede ir la ruta
	ld a,(0f885h)		;5483   ; la baldosa que se leyo del mapa
	cp 00ah		;5486   ; 0x0A, 0x0D, 0x09, 0x0F...
	jp z,anota		;5488
	cp 00dh		;548b
	jp z,anota		;548d
	cp 009h		;5490
	jp z,anota		;5492
	cp 00fh		;5495
	jp z,anota		;5497
	cp 007h		;549a   ; ...0x07, 0x08, 0x10, 0x11 y 0x0E: suelo
	jp z,anota		;549c
	cp 008h		;549f
	jp z,anota		;54a1
	cp 010h		;54a4
	jp z,anota		;54a6
	cp 011h		;54a9
	jp z,anota		;54ab
	cp 00eh		;54ae
	jp z,anota		;54b0
	cp 031h		;54b3   ; 0x31, 0xA4, 0xA3, 0x91...
	jp z,anota		;54b5
	cp 0a4h		;54b8
	jp z,anota		;54ba
	cp 0a3h		;54bd
	jp z,anota		;54bf
	cp 091h		;54c2
	jp z,anota		;54c4
	cp 05fh		;54c7   ; ...0x5F, 0x0C, 0x6D, 0x4A y 0xB8: mamparo
	jp z,anota		;54c9
	cp 00ch		;54cc
	jp z,anota		;54ce
	cp 06dh		;54d1
	jp z,anota		;54d3
	cp 04ah		;54d6
	jp z,anota		;54d8
	cp 0b8h		;54db
	jp z,anota		;54dd
	ret			;54e0   ; lo demas corta la ruta
baldosa_de_escala:		; Con el efecto 3 solo vale la 0x5C: la escala
	ld a,(0f885h)		;54e1
	cp 05ch		;54e4
	jp z,anota		;54e6
	ret			;54e9
reinicia_la_ruta:		; Deja el puntero de ruta en el principio de la lista
	ld hl,0cb1eh		;54ea
	ld (0f8afh),hl		;54ed
	ret			;54f0
borra_la_ruta:		; Deshace el rastro cuando hay que volver atras
	ld a,(0f8b3h)		;54f1   ; sin efecto no hay ruta que borrar
	and a			;54f4
	ret z			;54f5
	ld hl,(0f8afh)		;54f6
	ld de,0cb1eh		;54f9   ; con el puntero al principio tampoco
	rst 20h			;54fc
	ret z			;54fd
	ld de,0cb1ch		;54fe   ; se recorre la lista desde el principio
	ld (0f88dh),de		;5501
	ld a,(0f8b3h)		;5505   ; con el efecto 2 se borra de otra forma
	cp 002h		;5508
	jp z,rastro_del_fuego		;550a
L_550D:
	ld a,(de)			;550d   ; --- un punto por vuelta ---
	ld (0f89fh),a		;550e
	inc de			;5511
	ld a,(de)			;5512
	ld (0f8a0h),a		;5513
	inc de			;5516
	ld (0f88dh),de		;5517
	ld a,(0f8b3h)		;551b   ; efecto 1: la baldosa 0xF9
	cp 001h		;551e
	jp z,rastro_efecto_1		;5520
	cp 002h		;5523   ; efecto 2: la baldosa 0xFB
	jp z,rastro_efecto_2		;5525
	cp 003h		;5528   ; efecto 3: la baldosa 0x8F
	jp z,rastro_efecto_3		;552a
L_552D:
	ld a,(0f8b1h)		;552d   ; 0xF8B1 alterna la baldosa: el rastro parpadea
	add a,e			;5530
L_5531:
	call pinta_baldosa		;5531
L_5534:
	ld hl,(0f8afh)		;5534
	ld de,(0f88dh)		;5537
	rst 20h			;553b
	jp nz,L_550D		;553c
	ret			;553f
rastro_efecto_1:		; Baldosa base 0xF9
	ld e,0f9h		;5540
	jp L_552D		;5542
rastro_efecto_2:		; Baldosa base 0xFB
	ld e,0fbh		;5545
	jp L_552D		;5547
rastro_efecto_3:		; Baldosa 0x8F, sin parpadeo
	ld a,08fh		;554a
	jp L_5531		;554c
rastro_del_fuego:		; El rastro del efecto 2 se pinta con tres baldosas
	inc de			;554f
	inc de			;5550
	ld (0f88dh),de		;5551
	ld hl,(0cb1ch)		;5555   ; el punto de partida
	ld (0f89fh),hl		;5558
	call retrocede_columna		;555b
	call retrocede_columna		;555e
	call retrocede		;5561
	ld a,(0f8b1h)		;5564   ; 0xF8B1 alterna el dibujo
	and a			;5567
	call z,dos_atras		;5568
	ld a,0ffh		;556b   ; baldosas 0xFF, 0xFD y 0xFE
	call dibuja_y_baja		;556d
	ld a,0fdh		;5570
	call dibuja_y_baja		;5572
	ld a,0feh		;5575
	call dibuja_y_avanza		;5577
	call retrocede		;557a
	ld a,001h		;557d
	call dibuja_y_avanza		;557f
	ld a,001h		;5582
	call dibuja_y_avanza		;5584
	ld a,(0f8b1h)		;5587
	and a			;558a
	jp nz,L_5534		;558b
	ld a,001h		;558e
	call dibuja_y_avanza		;5590
	ld a,001h		;5593
	jp L_5531		;5595
dos_atras:		; Dos columnas hacia atras
	call retrocede_columna		;5598
	jp retrocede_columna		;559b
pinta_los_avisos:		; Los dos avisos de la carta
	ld a,(0f8c8h)		;559e   ; 0xF8C8: primera orden pendiente
	and a			;55a1
	jp nz,L_55AB		;55a2
	ld hl,(0f8c9h)		;55a5   ; su casilla esta en 0xF8C9
	call pinta_aviso		;55a8
L_55AB:
	ld a,(0f8cbh)		;55ab   ; 0xF8CB: segunda orden pendiente
	and a			;55ae
	ret nz			;55af
	ld hl,(0f8cch)		;55b0   ; su casilla, en 0xF8CC
pinta_aviso:		; Las dos baldosas del aviso: 0x9F y 0xA0
	ld (0f89fh),hl		;55b3
	ld a,09fh		;55b6
	call dibuja_y_avanza		;55b8
	ld a,0a0h		;55bb
	jp pinta_baldosa		;55bd
luz_de_aviso:		; Enciende o apaga el LED de CAPS como alarma
	ld a,(0f897h)		;55c0   ; solo con el barco 3, el que lleva el jugador
	cp 003h		;55c3
	ret nz			;55c5
	ld a,(0f898h)		;55c6
	ld e,a			;55c9
	ld a,(0f8c8h)		;55ca   ; 0xF8C8: hay orden pendiente...
	and a			;55cd
	jp z,L_55D8		;55ce
	ld a,(0f8c0h)		;55d1   ; ...y es para este tripulante
	cp e			;55d4
	jp z,L_55EB		;55d5
L_55D8:
	ld a,(0f8cbh)		;55d8   ; lo mismo con la segunda orden
	and a			;55db
	jp z,L_55E6		;55dc
	ld a,(0f8c1h)		;55df
	cp e			;55e2
	jp z,L_55EB		;55e3
L_55E6:
	ld a,0ffh		;55e6   ; CHGCAP con 0xFF apaga la luz...
	jp 00132h		;55e8   ; BIOS CHGCAP - Alternates the CAPS lamp status
L_55EB:
	xor a			;55eb   ; ...y con 0, la enciende
	jp 00132h		;55ec   ; BIOS CHGCAP - Alternates the CAPS lamp status
tecla_de_orden:		; Mira la fila 3 del teclado: la tecla que da la orden
	ld a,(0f897h)		;55ef
	cp 003h		;55f2   ; solo con el barco 3
	ret nz			;55f4
	ei			;55f5
	ld a,003h		;55f6   ; SNSMAT lee la fila 3 de la matriz
	call 00141h		;55f8   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cp 0feh		;55fb   ; 0xFE: la tecla que corresponde al bit 0
	ret nz			;55fd
	call estado_de		;55fe   ; el estado del tripulante
	ld a,(hl)			;5601
	cp 007h		;5602   ; al que ya esta caido no se le manda nada
	ret z			;5604
	call casilla_del_muneco		;5605   ; su casilla en el mapa
	ld de,(0f89fh)		;5608
	ld a,(0f8c8h)		;560c
	and a			;560f
	jp nz,L_5628		;5610
	ld hl,(0f8c9h)		;5613   ; la casilla de la primera orden
	call esta_cerca		;5616
	and a			;5619
	jp z,L_5628		;561a
	ld a,001h		;561d   ; se apunta la orden...
	ld (0f8c8h),a		;561f
	ld a,(0f898h)		;5622   ; ...y para quien es
	ld (0f8c0h),a		;5625
L_5628:
	ld a,(0f8cbh)		;5628   ; --- la segunda orden ---
	and a			;562b
	ret nz			;562c
	ld hl,(0f8cch)		;562d   ; su casilla, en 0xF8CC
	call esta_cerca		;5630   ; se mira si el tripulante esta cerca
	and a			;5633
	ret z			;5634
	ld a,001h		;5635   ; y se apunta a quien le toca
	ld (0f8cbh),a		;5637
	ld a,(0f898h)		;563a
	ld (0f8c1h),a		;563d
	ret			;5640
esta_cerca:		; Compara la posicion con cuatro casillas alrededor
	rst 20h			;5641   ; la casilla de la orden
	jp z,acepta_la_orden		;5642
	inc d			;5645   ; una fila mas abajo
	rst 20h			;5646
	jp z,acepta_la_orden		;5647
	inc d			;564a
	rst 20h			;564b
	jp z,acepta_la_orden		;564c
	inc d			;564f
	rst 20h			;5650
	jp z,acepta_la_orden		;5651
	xor a			;5654   ; no esta cerca
L_5655:
	dec d			;5655   ; se deshacen las tres filas sumadas
	dec d			;5656
	dec d			;5657
	ret			;5658
acepta_la_orden:		; El tripulante acude: suena y se le pone en camino
	call 000c0h		;5659   ; BIOS BEEP - Generates beep | BEEP
	call sonido_corto		;565c   ; y el pitido del PSG
	ld a,(0f898h)		;565f
	ld e,a			;5662
	xor a			;5663
	ld d,a			;5664
	ld hl,0f8d6h		;5665   ; 0xF8D6 es el cansancio
	add hl,de			;5668
	ld a,(hl)			;5669
	cp 003h		;566a   ; al agotado no se le manda
	jp z,L_5655		;566c
	ld hl,0f8a3h		;566f   ; y si no, estado 7: en camino
	add hl,de			;5672
	ld a,007h		;5673
	ld (hl),a			;5675
	jp L_5655		;5676
anula_orden:		; La tecla que cancela la orden dada
	ld a,(0f897h)		;5679
	cp 003h		;567c   ; solo con el barco 3
	ret nz			;567e
	ld a,(0f89bh)		;567f   ; trepando no se dan ordenes
	and a			;5682
	ret nz			;5683
	ei			;5684
	ld a,003h		;5685   ; SNSMAT lee la fila 3
	call 00141h		;5687   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cp 0fdh		;568a   ; 0xFD: la tecla del bit 1
	ret nz			;568c
	ld a,(0f898h)		;568d
	ld e,a			;5690
	ld a,(0f8c8h)		;5691
	and a			;5694
	jp z,comprueba_segunda		;5695
	ld a,(0f8c0h)		;5698
	cp e			;569b
	jp z,L_56A9		;569c
comprueba_segunda:		; Mira si la orden que se anula es la segunda
	ld a,(0f8cbh)		;569f   ; 0xF8CB: hay segunda orden
	and a			;56a2
	ret z			;56a3
	ld a,(0f8c1h)		;56a4   ; y es para este tripulante
	cp e			;56a7
	ret nz			;56a8
L_56A9:
	ld hl,0f8c8h		;56a9   ; se borra la orden que estuviera puesta
	ld a,(hl)			;56ac
	and a			;56ad
	jp nz,L_56B4		;56ae
	ld hl,0f8cbh		;56b1
L_56B4:
	xor a			;56b4   ; la casilla del muñeco...
	ld (hl),a			;56b5
	push hl			;56b6
	call casilla_del_muneco		;56b7
	pop hl			;56ba
	ld de,(0f89fh)		;56bb   ; ...que pasa a ser la de la orden
	inc d			;56bf   ; dos filas mas abajo: donde se le deja
	inc d			;56c0
	inc hl			;56c1
	ld (hl),e			;56c2   ; se guarda la columna...
	inc hl			;56c3
	ld (hl),d			;56c4   ; ...y la fila
	ld a,(0f898h)		;56c5
	ld e,a			;56c8
	xor a			;56c9
	ld d,a			;56ca
	ld hl,0f8a3h		;56cb   ; y el tripulante vuelve al estado 0
	add hl,de			;56ce
	xor a			;56cf
	ld (hl),a			;56d0
	ret			;56d1
casilla_del_muneco:		; Convierte la posicion en pixeles a casilla del mapa
	call apunta_al_barco		;56d2
	ld a,001h		;56d5   ; el campo 1 de la ficha: la X fina
	call campo_del_barco		;56d7
	add a,004h		;56da   ; +4 y dividido entre 8
	srl a		;56dc
	srl a		;56de
	srl a		;56e0
	ld e,a			;56e2
	ld a,(0f88fh)		;56e3   ; mas el scroll horizontal
	add a,e			;56e6
	ld (0f89fh),a		;56e7
	ld a,002h		;56ea   ; el campo 2: la Y fina
	call campo_del_barco		;56ec
	add a,004h		;56ef
	srl a		;56f1
	srl a		;56f3
	srl a		;56f5
	ld e,a			;56f7
	ld a,(0f890h)		;56f8   ; mas el scroll vertical
	add a,e			;56fb
	ld (0f8a0h),a		;56fc
	ret			;56ff
cambia_el_cielo:		; Cambia el color del borde y la fuente segun la hora del dia
	ld a,(0f8b1h)		;5700   ; trepando no se toca nada
	and a			;5703
	ret nz			;5704
	ld a,(0f8bch)		;5705   ; 0xF8BC es la hora, de 0 a 15
	cp 003h		;5708   ; antes de las 3: de noche
	jp c,L_571C		;570a
	cp 005h		;570d   ; antes de las 5: amanecer
	jp c,L_5767		;570f
	cp 00bh		;5712   ; antes de las 11: de dia
	jp c,cielo_de_dia		;5714
	cp 00dh		;5717   ; antes de las 13: atardecer
	jp c,L_5767		;5719
L_571C:
	ld a,(0f8d0h)		;571c   ; --- de noche ---
	and a			;571f   ; si aun no esta puesta, se cambia la fuente
	call z,fuente_de_noche		;5720
	ld a,001h		;5723   ; tinta 1 sobre el cielo
	ld (0f8ceh),a		;5725
	ld a,(0f8cfh)		;5728   ; 0xF8CF es el color del cielo, que va bajando
	cp 00fh		;572b   ; 0x0F, 0x0E, 0x0B, 0x07, 0x09 y 0x08: el degradado
	jp z,L_574E		;572d
	cp 00eh		;5730
	jp z,L_5753		;5732
	cp 00bh		;5735
	jp z,L_5758		;5737
	cp 007h		;573a
	jp z,L_575D		;573c
	cp 009h		;573f
	jp z,L_5762		;5741
	ld a,00fh		;5744
L_5746:
	ld e,001h		;5746
	ld (0f8cfh),a		;5748
	jp L_577A		;574b
L_574E:
	ld a,00eh		;574e
	jp L_5746		;5750
L_5753:
	ld a,00bh		;5753
	jp L_5746		;5755
L_5758:
	ld a,007h		;5758
	jp L_5746		;575a
L_575D:
	ld a,009h		;575d
	jp L_5746		;575f
L_5762:
	ld a,008h		;5762
	jp L_5746		;5764
L_5767:
	ld a,(0f8d0h)		;5767   ; --- amanecer y atardecer ---
	and a			;576a
	call z,fuente_de_noche		;576b
	ld a,(0f8ceh)		;576e   ; color 4
	cp 004h		;5771
	ret z			;5773
	ld a,004h		;5774
L_5776:
	ld e,a			;5776
	ld (0f8ceh),a		;5777
L_577A:
	sla a		;577a   ; el registro 7 lleva tinta y borde en un solo byte
	sla a		;577c
	sla a		;577e
	sla a		;5780
	add a,e			;5782
	ld (0f87fh),a		;5783
	ld hl,02000h		;5786   ; los colores de la parte de arriba de la pantalla
	call pinta_franja_de_cielo		;5789
	ld hl,020b0h		;578c
	call pinta_franja_de_cielo		;578f
	ld a,(0f8ceh)		;5792
	add a,0f0h		;5795
	ld hl,02530h		;5797   ; 0x2530: una franja de 0x20 bytes de color
	ld bc,00020h		;579a
	call 00056h		;579d   ; BIOS FILVRM - Fills VRAM with value
	ld a,(0f8ceh)		;57a0
	add a,060h		;57a3
	ld hl,02308h		;57a5   ; y una baldosa mas
	ld bc,00008h		;57a8
	call 00056h		;57ab   ; BIOS FILVRM - Fills VRAM with value
	ld a,(0f8ceh)		;57ae
escribe_registro_7:		; WRTVDP del registro 7: tinta y color del borde
	ld b,a			;57b1
	ld c,007h		;57b2
	jp 00047h		;57b4   ; BIOS WRTVDP - Writes data in the VDP-register
pinta_franja_de_cielo:		; Ocho bytes de color a partir de HL
	ld a,(0f87fh)		;57b7
	ld bc,00008h		;57ba
	jp 00056h		;57bd   ; BIOS FILVRM - Fills VRAM with value
cielo_de_dia:		; El cielo claro del mediodia
	ld a,(0f8d0h)		;57c0
	and a			;57c3
	call nz,repon_la_fuente		;57c4   ; si estaba la fuente de noche, se repone la de dia
	ld a,(0f8ceh)		;57c7
	cp 007h		;57ca
	ret z			;57cc
	ld a,007h		;57cd   ; color 7
	jp L_5776		;57cf
repon_la_fuente:		; Vuelve a la fuente de dia
	xor a			;57d2
	ld (0f8d0h),a		;57d3
	jp carga_fuente		;57d6
fuente_de_noche:		; Cambia dos trozos de la tabla de colores: se hace de noche
	ld a,001h		;57d9   ; 0xF8D0 marca que la fuente de noche esta puesta
	ld (0f8d0h),a		;57db
	ld hl,02328h		;57de   ; 0x2328: la primera franja de color
	ld (0f881h),hl		;57e1
	ld hl,00010h		;57e4   ; 0x10 bytes
	ld (0f883h),hl		;57e7
	ld hl,0cb96h		;57ea   ; los colores de noche, en 0xCB96
	ld (0f87fh),hl		;57ed
	call vuelca_tres_tercios		;57f0
	ld hl,02378h		;57f3   ; 0x2378: la segunda franja
	ld (0f881h),hl		;57f6
	ld hl,00020h		;57f9
	ld (0f883h),hl		;57fc
	ld hl,0cba6h		;57ff   ; con 0x20 bytes mas, en 0xCBA6
	ld (0f87fh),hl		;5802
	jp vuelca_tres_tercios		;5805
quita_punto_de_ruta:		; Retira el ultimo punto anotado
	ld a,(0f8b1h)		;5808
	and a			;580b   ; trepando no se toca
	ret nz			;580c
	ld a,(0f8d1h)		;580d   ; 0xF8D1: hace falta relevo
	and a			;5810
	ret z			;5811
	ld hl,(0f8afh)		;5812
	ld de,0cb1eh		;5815   ; con la ruta vacia no hay nada que quitar
	rst 20h			;5818
	ret z			;5819
	ld hl,(0f8afh)		;581a
	dec hl			;581d   ; dos bytes atras: un punto
	dec hl			;581e
	ld (0f8afh),hl		;581f
	ld de,0cb1eh		;5822
	rst 20h			;5825
	ret nz			;5826
	xor a			;5827   ; y sin ruta, sin efecto
	ld (0f8b3h),a		;5828
	ret			;582b
fin_de_la_travesia:		; Comprueba si el barco ha llegado y salta al final
	ld a,(0f8a2h)		;582c   ; 0xF8A2: hace falta la vela puesta
	and a			;582f
	ret z			;5830
	ld a,(0f897h)		;5831   ; y ser el barco 0
	and a			;5834
	ret nz			;5835
	call casilla_del_muneco		;5836   ; la casilla del muñeco
	ld hl,(0f89fh)		;5839
	ld de,01c0dh		;583c   ; 0x1C0D y 0x1B0D: las dos casillas del timon
	rst 20h			;583f
	jp z,L_5848		;5840
	ld de,01b0dh		;5843
	rst 20h			;5846
	ret nz			;5847
L_5848:
	call lee_gatillo		;5848   ; hay que pulsar el gatillo
	cp 0ffh		;584b
	ret nz			;584d
	call 000c0h		;584e   ; BIOS BEEP - Generates beep | BEEP
	ei			;5851
	ld a,001h		;5852   ; el registro 7, con el borde a 1
	call escribe_registro_7		;5854
	ld a,002h		;5857   ; SCREEN 2
	call 0005fh		;5859   ; BIOS CHGMOD - Switches to given screen mode
	call carga_fuente_de_carta		;585c   ; la fuente de la carta
	ld hl,0b358h		;585f   ; y la tabla de nombres de la carta
	ld de,01800h		;5862
	ld bc,00300h		;5865
	call 0005ch		;5868   ; BIOS LDIRVM - Block transfers to VRAM from memory
L_586B:
	call escribe_dias		;586b   ; --- el bucle de la carta oceanica ---
	call barra_moral		;586e
	call barra_fisica		;5871
	call barras_tripulacion		;5874
	call marca_en_la_carta		;5877
	call mira_el_viento		;587a
	call lee_gatillo		;587d   ; se sale con el gatillo
	cp 0ffh		;5880
	jp nz,L_586B		;5882
	pop hl			;5885   ; el POP tira la vuelta pendiente del bucle principal
	jp L_407F		;5886
carga_fuente_de_carta:		; La otra fuente: patrones en 0xB958 y colores en 0xC158
	ld hl,00800h		;5889   ; 0x800 bytes: 256 baldosas
	ld (0f883h),hl		;588c
	ld hl,00000h		;588f
	ld (0f881h),hl		;5892
	ld hl,0b958h		;5895   ; los patrones, en 0xB958
	ld (0f87fh),hl		;5898
	call vuelca_tres_tercios		;589b
	ld hl,02000h		;589e   ; y a la tabla de colores
	ld (0f881h),hl		;58a1
	ld hl,0c158h		;58a4   ; los colores, en 0xC158
	ld (0f87fh),hl		;58a7
	jp vuelca_tres_tercios		;58aa
escribe_dias:		; Los dos digitos del contador de dias
	ld hl,01862h		;58ad   ; 0x1862: la casilla de las decenas
	ld a,(0f8d3h)		;58b0
	add a,02dh		;58b3   ; 0x2D: la baldosa del digito 0
	call 0004dh		;58b5   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;58b8
	ld a,(0f8d4h)		;58b9   ; y las unidades al lado
	add a,02dh		;58bc
	jp 0004dh		;58be   ; BIOS WRTVRM - Writes data in VRAM
barra_moral:		; Pinta la barra del estado moral
	ld hl,01921h		;58c1   ; 0x1921: donde empieza la barra
	ld (0f87fh),hl		;58c4
	ld a,(0f8d5h)		;58c7   ; 0xF8D5 es lo que se ha perdido...
	ld e,a			;58ca
	ld a,004h		;58cb   ; ...de cuatro tramos
	sub e			;58cd
	ld (0f881h),a		;58ce
L_58D1:
	ld a,(0f881h)		;58d1   ; --- un tramo por vuelta ---
	and a			;58d4
	ret z			;58d5
	ld hl,(0f87fh)		;58d6
	ld a,037h		;58d9   ; 0x37: la baldosa del tramo lleno
	call 0004dh		;58db   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;58de
	ld (0f87fh),hl		;58df
	ld a,(0f881h)		;58e2
	dec a			;58e5
	ld (0f881h),a		;58e6
	jp L_58D1		;58e9
barra_fisica:		; Pinta la barra del estado fisico
	ld a,(0f8b9h)		;58ec   ; 0xF8B9 es el contratiempo en curso
	and a			;58ef
	jp z,L_5906		;58f0   ; sin contratiempo, un solo tramo
	cp 002h		;58f3   ; con el 2, dos
	jp z,L_590B		;58f5
	ld a,004h		;58f8   ; y con los demas, cuatro
L_58FA:
	ld (0f881h),a		;58fa
	ld hl,01afch		;58fd   ; 0x1AFC: donde empieza esta barra
	ld (0f87fh),hl		;5900
	jp L_58D1		;5903
L_5906:
	ld a,001h		;5906
	jp L_58FA		;5908
L_590B:
	ld a,002h		;590b
	jp L_58FA		;590d
barras_tripulacion:		; Una barra por miembro de la tripulacion
	xor a			;5910
	ld (0f882h),a		;5911   ; 0xF882 recorre la tripulacion
L_5914:
	ld a,(0f882h)		;5914
	ld e,a			;5917
	ld a,(0f39fh)		;5918   ; 0xF39F es cuantos son
	cp e			;591b
	ret z			;591c
	ld a,(0f882h)		;591d
	ld hl,019e2h		;5920   ; 0x19E2: la primera barra
	ld de,00020h		;5923   ; y cada una, una fila mas abajo
L_5926:
	and a			;5926
	jp z,L_592F		;5927
	dec a			;592a
	add hl,de			;592b
	jp L_5926		;592c
L_592F:
	ld (0f87fh),hl		;592f
	ld a,(0f882h)		;5932
	ld e,a			;5935
	xor a			;5936
	ld d,a			;5937
	ld hl,0f8d6h		;5938   ; 0xF8D6 es el cansancio del tripulante
	add hl,de			;593b
	ld a,(hl)			;593c
	ld e,a			;593d
	ld a,003h		;593e   ; tres tramos menos el cansancio
	sub e			;5940
	ld (0f881h),a		;5941
	call L_58D1		;5944
	ld hl,0f882h		;5947
	inc (hl)			;594a
	jp L_5914		;594b
marca_en_la_carta:		; Pinta la posicion del barco en la carta oceanica
	ld a,(0f8b7h)		;594e
	ld e,a			;5951
	xor a			;5952
	ld d,a			;5953
	ld hl,01849h		;5954   ; 0x1849: la esquina de la carta en la pantalla
	add hl,de			;5957
	ld a,(0f8b8h)		;5958
	ld de,00020h		;595b   ; y cada fila son 0x20 baldosas
L_595E:
	and a			;595e
	jp z,L_5967		;595f
	dec a			;5962
	add hl,de			;5963
	jp L_595E		;5964
L_5967:
	ld a,(0f8bfh)		;5967   ; 0xF8BF es el rumbo
	and a			;596a
	jp z,L_597D		;596b
	cp 001h		;596e
	jp z,L_5982		;5970
	cp 002h		;5973
	jp z,L_5987		;5975
	ld a,012h		;5978   ; baldosa 0x12: rumbo sur
	jp 0004dh		;597a   ; BIOS WRTVRM - Writes data in VRAM
L_597D:
	ld a,00fh		;597d   ; baldosa 0x0F: rumbo poniente
	jp 0004dh		;597f   ; BIOS WRTVRM - Writes data in VRAM
L_5982:
	ld a,011h		;5982   ; baldosa 0x11: rumbo levante
	jp 0004dh		;5984   ; BIOS WRTVRM - Writes data in VRAM
L_5987:
	ld a,010h		;5987   ; baldosa 0x10: rumbo norte
	jp 0004dh		;5989   ; BIOS WRTVRM - Writes data in VRAM
mira_el_viento:		; Cuenta los tripulantes en su puesto y da el rumbo
	ld a,(0f39fh)		;598c   ; 0xF39F es cuantos son
	ld (0f87fh),a		;598f
	ld hl,0f8a3h		;5992   ; la tabla de estados
L_5995:
	and a			;5995   ; --- busca uno con el estado 5 ---
	ret z			;5996
	ld a,(hl)			;5997
	cp 005h		;5998
	jp z,L_59A8		;599a
	ld a,(0f87fh)		;599d
	dec a			;59a0
	ld (0f87fh),a		;59a1
	inc hl			;59a4
	jp L_5995		;59a5
L_59A8:
	call lee_mando		;59a8   ; el mando dice hacia donde
	cp 001h		;59ab   ; 1: rumbo poniente
	jp z,L_59C0		;59ad
	cp 003h		;59b0   ; 3: levante
	jp z,L_59C6		;59b2
	cp 005h		;59b5   ; 5: norte
	jp z,L_59CB		;59b7
	cp 007h		;59ba   ; 7: sur
	jp z,L_59D0		;59bc
	ret			;59bf
L_59C0:
	ld a,001h		;59c0
pon_rumbo:		; Deja el rumbo en 0xF8BF
	ld (0f8bfh),a		;59c2
	ret			;59c5
L_59C6:
	ld a,002h		;59c6
	jp pon_rumbo		;59c8
L_59CB:
	ld a,003h		;59cb
	jp pon_rumbo		;59cd
L_59D0:
	xor a			;59d0
	jp pon_rumbo		;59d1
cuenta_dia:		; Suma un dia al contador de dos digitos
	ld a,(0f8d4h)		;59d4   ; 0xF8D4 son las unidades
	inc a			;59d7
	ld (0f8d4h),a		;59d8
	cp 00ah		;59db   ; a las diez, se lleva una
	ret nz			;59dd
	xor a			;59de
	ld (0f8d4h),a		;59df
	ld a,(0f8d3h)		;59e2   ; 0xF8D3 son las decenas
	inc a			;59e5
	ld (0f8d3h),a		;59e6
	cp 00ah		;59e9   ; y a las diez, vuelta a empezar
	ret nz			;59eb
	xor a			;59ec
	ld (0f8d3h),a		;59ed
	ret			;59f0
desanima:		; Con el contratiempo en marcha, la moral baja un punto
	ld a,(0f8dfh)		;59f1   ; 0xF8DF marca que hay contratiempo activo
	and a			;59f4
	ret z			;59f5
	ld a,(0f8d5h)		;59f6   ; 0xF8D5 es lo perdido de moral
	cp 004h		;59f9   ; al cuarto, motin
	jp z,L_5A03		;59fb
	ld hl,0f8d5h		;59fe
	inc (hl)			;5a01
	ret			;5a02
L_5A03:
	ld a,001h		;5a03   ; 0xF8DE a 1: el desenlace por desmoralizacion
	ld (0f8deh),a		;5a05
	call marca_ruta_en_carta		;5a08
	ret			;5a0b
desgasta_tripulacion:		; Va cansando a los que llevan mucho tiempo trabajando
	ld a,(0f39fh)		;5a0c   ; 0xF39F es cuantos son
	ld (0f87fh),a		;5a0f
	ld hl,0f8a3h		;5a12   ; la tabla de estados...
	ld de,0f8d6h		;5a15   ; ...y la de cansancio
L_5A18:
	ld a,(0f87fh)		;5a18   ; --- uno por vuelta ---
	and a			;5a1b
	ret z			;5a1c
	ld a,(hl)			;5a1d
	cp 004h		;5a1e   ; estado 4: en un puesto de trabajo; ese descansa
	jp z,L_5A46		;5a20
	ld a,(de)			;5a23
	cp 003h		;5a24   ; con el cansancio ya a 3, no se sube mas
	jp z,L_5A31		;5a26
	ld a,(de)			;5a29
	inc a			;5a2a   ; un punto de cansancio
	ld (de),a			;5a2b
	cp 003h		;5a2c
	jp nz,L_5A3A		;5a2e
L_5A31:
	ld a,(hl)			;5a31
	cp 004h		;5a32
	jp z,L_5A3A		;5a34
	ld a,006h		;5a37   ; y al llegar a 3 se le manda al estado 6
	ld (hl),a			;5a39
L_5A3A:
	ld a,(0f87fh)		;5a3a   ; --- pasa al tripulante siguiente ---
	dec a			;5a3d
	ld (0f87fh),a		;5a3e
	inc hl			;5a41   ; las dos tablas avanzan a la vez
	inc de			;5a42
	jp L_5A18		;5a43
L_5A46:
	ld a,(de)			;5a46   ; el que descansa va recuperando
	and a			;5a47
	jp z,L_5A3A		;5a48
	ld a,(de)			;5a4b
	dec a			;5a4c
	ld (de),a			;5a4d
	jp L_5A3A		;5a4e
gasta_provisiones:		; Descuenta bebida y comida cada 30 unidades de tiempo
	ld a,(0f39fh)		;5a51   ; 0xF39F, la tripulacion: cuantos mas van a bordo, mas se gasta
	ld e,a			;5a54
	ld a,(0f8e0h)		;5a55   ; 0xF8E0 acumula el gasto de bebida
	add a,e			;5a58
	ld (0f8e0h),a		;5a59
	ld a,(0f8e1h)		;5a5c   ; y 0xF8E1 el de comida
	add a,e			;5a5f
	ld (0f8e1h),a		;5a60
	ld a,(0f8e0h)		;5a63
	cp 01eh		;5a66   ; cada 30 unidades se descuenta una racion
	jp c,L_5A89		;5a68
	sub 01eh		;5a6b
	ld (0f8e0h),a		;5a6d
	ld a,(0f39ah)		;5a70   ; 0xF39A: primero se bebe el AGUA...
	and a			;5a73
	jp z,L_5A7E		;5a74
	dec a			;5a77
	ld (0f39ah),a		;5a78
	jp L_5A89		;5a7b
L_5A7E:
	ld a,(0f39bh)		;5a7e   ; ...y cuando se acaba, el VINO
	and a			;5a81
	jp z,L_5AA0		;5a82
	dec a			;5a85
	ld (0f39bh),a		;5a86
L_5A89:
	ld a,(0f8e1h)		;5a89   ; --- la COMIDA, con su propio contador ---
	cp 01eh		;5a8c   ; tambien cada 30 unidades
	ret c			;5a8e
	sub 01eh		;5a8f
	ld (0f8e1h),a		;5a91
	ld a,(0f39eh)		;5a94   ; 0xF39E: lo que queda de comida
	and a			;5a97
	jp z,L_5AA0		;5a98
	dec a			;5a9b   ; una racion menos
	ld (0f39eh),a		;5a9c
	ret			;5a9f
L_5AA0:
	ld a,002h		;5aa0   ; sin nada que comer ni beber, el desenlace 2: AGOTADAS PROVISIONES
	ld (0f8deh),a		;5aa2
	call marca_ruta_en_carta		;5aa5
	ret			;5aa8
penaliza:		; Aplica el castigo de la casilla en la que se ha caido
	ld a,(0f8b9h)		;5aa9   ; 0xF8B9 es el contratiempo
	and a			;5aac   ; los valores 0, 1 y 2 no castigan
	ret z			;5aad
	cp 001h		;5aae
	ret z			;5ab0
	cp 002h		;5ab1
	ret z			;5ab3
	ld a,(0f8b3h)		;5ab4   ; 0xF8B3 dice si se esta atendiendo
	and a			;5ab7
	jp nz,L_5AD0		;5ab8
	ld a,(0f8b9h)		;5abb   ; contratiempos 6, 7 y 8: se gasta MADERA
	cp 006h		;5abe
	ret c			;5ac0
	cp 009h		;5ac1
	jp c,L_5ACB		;5ac3   ; del 9 en adelante: se gasta TELA
	ld hl,(0f39dh)		;5ac6
	dec (hl)			;5ac9
	ret			;5aca
L_5ACB:
	ld hl,(0f39ch)		;5acb
	dec (hl)			;5ace
	ret			;5acf
L_5AD0:
	ld a,(0f8b3h)		;5ad0   ; con el contratiempo atendido...
	cp 001h		;5ad3   ; ...cada efecto tiene su desenlace
	jp z,L_5AE6		;5ad5
	cp 002h		;5ad8
	jp z,L_5AEB		;5ada
	ld a,005h		;5add
L_5ADF:
	ld (0f8deh),a		;5adf
	call marca_ruta_en_carta		;5ae2
	ret			;5ae5
L_5AE6:
	ld a,004h		;5ae6
	jp L_5ADF		;5ae8
L_5AEB:
	ld a,003h		;5aeb
	jp L_5ADF		;5aed
pantalla_de_desastre:		; El motin, el fuego, la via de agua... con su mensaje
	ld a,(0f8deh)		;5af0   ; 0xF8DE es el desenlace; a cero no hay ninguno
	and a			;5af3
	ret z			;5af4
	ld a,007h		;5af5   ; el registro 7, con el borde a 7
	call escribe_registro_7		;5af7
	ld a,002h		;5afa   ; SCREEN 2
	call 0005fh		;5afc   ; BIOS CHGMOD - Switches to given screen mode
	call carga_fuente_de_carta		;5aff   ; la fuente de la carta
	ld hl,0b658h		;5b02   ; y la tabla de nombres del final
	ld de,01800h		;5b05
	ld bc,00300h		;5b08
	call 0005ch		;5b0b   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld a,(0f8deh)		;5b0e   ; el mensaje que toca
	ld hl,0cbdch		;5b11   ; los cinco mensajes empiezan en 0xCBDC
	ld de,00016h		;5b14   ; y miden 0x16 = 22 caracteres
L_5B17:
	and a			;5b17   ; --- salta hasta el mensaje pedido ---
	jp z,L_5B20		;5b18
	dec a			;5b1b
	add hl,de			;5b1c
	jp L_5B17		;5b1d
L_5B20:
	ld (0f87fh),hl		;5b20
	xor a			;5b23
	ld (0f881h),a		;5b24
	ld hl,004e8h		;5b27   ; 0x4E8: la baldosa donde se escribe
	ld (0f885h),hl		;5b2a
L_5B2D:
	ld hl,(0f87fh)		;5b2d   ; --- una letra por vuelta ---
	ld a,(hl)			;5b30
	ld e,a			;5b31
	xor a			;5b32
	ld d,a			;5b33
	ld hl,01bbfh		;5b34   ; 0x1BBF es CGTABL, la fuente de la ROM
	add hl,de			;5b37   ; ocho bytes por caracter
	add hl,de			;5b38
	add hl,de			;5b39
	add hl,de			;5b3a
	add hl,de			;5b3b
	add hl,de			;5b3c
	add hl,de			;5b3d
	add hl,de			;5b3e
	ld (0f883h),hl		;5b3f
	ld hl,(0f883h)		;5b42
	ld de,(0f885h)		;5b45
	ld bc,00008h		;5b49   ; el patron de la letra, a la tabla de patrones
	call 0005ch		;5b4c   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld hl,(0f885h)		;5b4f
	ld de,00008h		;5b52
	add hl,de			;5b55
	ld (0f885h),hl		;5b56
	ld hl,(0f87fh)		;5b59
	inc hl			;5b5c
	ld (0f87fh),hl		;5b5d
	call 000c0h		;5b60   ; BIOS BEEP - Generates beep | BEEP: una letra, un pitido
	ld a,(0f881h)		;5b63
	inc a			;5b66
	ld (0f881h),a		;5b67
	cp 016h		;5b6a   ; las 22 letras del mensaje
	jp nz,L_5B2D		;5b6c
	jp rotulo_de_final		;5b6f
marca_ruta_en_carta:		; Pinta un punto del rastro en la carta
	ld a,(0f8b7h)		;5b72
	ld e,a			;5b75
	xor a			;5b76
	ld d,a			;5b77
	ld hl,0b3a1h		;5b78   ; 0xB3A1: la esquina de la carta en su tabla de nombres
	add hl,de			;5b7b
	ld a,(0f8b8h)		;5b7c   ; y cada fila son 0x20 baldosas
	ld de,00020h		;5b7f
L_5B82:
	and a			;5b82
	jp z,L_5B8B		;5b83
	dec a			;5b86
	add hl,de			;5b87
	jp L_5B82		;5b88
L_5B8B:
	ld a,01ch		;5b8b   ; 0x1C: la baldosa del rastro
	ld (hl),a			;5b8d
	ret			;5b8e
rotulo_de_final:		; Las tres lineas de abajo de la pantalla de final
	ld hl,0cc60h		;5b8f   ; 0x14 = 20 baldosas por linea
	ld de,01a86h		;5b92   ; 0x1A86: la primera linea
	ld bc,00014h		;5b95
	call 0005ch		;5b98   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld hl,0cc74h		;5b9b
	ld de,01aa6h		;5b9e   ; la segunda, una fila mas abajo
	ld bc,00014h		;5ba1
	call 0005ch		;5ba4   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld hl,0cc88h		;5ba7
	ld de,01ac6h		;5baa   ; y la tercera
	ld bc,00014h		;5bad
	call 0005ch		;5bb0   ; BIOS LDIRVM - Block transfers to VRAM from memory
	call 000c0h		;5bb3   ; BIOS BEEP - Generates beep | BEEP
L_5BB6:
	call lee_gatillo		;5bb6   ; --- espera al gatillo ---
	cp 0ffh		;5bb9
	jp nz,L_5BB6		;5bbb
	pop hl			;5bbe   ; el POP tira la vuelta pendiente y se vuelve a empezar
	jp principal		;5bbf
llegada:		; La pantalla de FINAL DE LA TRAVESIA
	ld a,(0f8deh)		;5bc2   ; 0xFF en 0xF8DE es el desenlace bueno
	cp 0ffh		;5bc5
	ret nz			;5bc7
	ld a,001h		;5bc8   ; el registro 7, con el borde a 1
	call escribe_registro_7		;5bca
	ld a,002h		;5bcd   ; SCREEN 2
	call 0005fh		;5bcf   ; BIOS CHGMOD - Switches to given screen mode
	call carga_fuente_de_carta		;5bd2
	ld hl,0b358h		;5bd5   ; la tabla de nombres de la carta
	ld de,01800h		;5bd8
	ld bc,00300h		;5bdb
	call 0005ch		;5bde   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld hl,0cc9ch		;5be1   ; 0xCC9C: veinte filas de tres baldosas
	ld (0f87fh),hl		;5be4
	ld hl,01846h		;5be7   ; 0x1846: donde se pintan
	ld (0f881h),hl		;5bea
L_5BED:
	ld hl,(0f87fh)		;5bed   ; --- tres baldosas por vuelta ---
	ld de,(0f881h)		;5bf0
	ld bc,00003h		;5bf4
	call 0005ch		;5bf7   ; BIOS LDIRVM - Block transfers to VRAM from memory
	call 000c0h		;5bfa   ; BIOS BEEP - Generates beep | BEEP
	ld hl,(0f87fh)		;5bfd
	inc hl			;5c00
	inc hl			;5c01
	inc hl			;5c02
	ld (0f87fh),hl		;5c03
	ld hl,(0f881h)		;5c06   ; la fila siguiente, 0x20 mas alla
	ld de,00020h		;5c09
	add hl,de			;5c0c
	ld (0f881h),hl		;5c0d
	ld hl,(0f87fh)		;5c10
	ld de,0ccd8h		;5c13   ; hasta 0xCCD8, el final de la lista
	rst 20h			;5c16
	jp nz,L_5BED		;5c17
	jp rotulo_de_final		;5c1a
lee_mando:		; Deja en 0xF891 la direccion del mando o del cursor
	xor a			;5c1d   ; primero el cursor del teclado...
	call 000d5h		;5c1e   ; BIOS GTSTCK - Returns the joystick status
	and a			;5c21
	jp nz,L_5C2A		;5c22
	ld a,001h		;5c25   ; ...y si no hay nada, el mando del puerto 1
	call 000d5h		;5c27   ; BIOS GTSTCK - Returns the joystick status
L_5C2A:
	ld (0f891h),a		;5c2a
	ret			;5c2d
lee_gatillo:		; Deja en 0xF892 el gatillo o la barra
	xor a			;5c2e   ; primero la barra espaciadora...
	call 000d8h		;5c2f   ; BIOS GTTRIG - Returns current trigger status
	and a			;5c32
	jp nz,L_5C3B		;5c33
	ld a,001h		;5c36   ; ...y si no, el boton del mando
	call 000d8h		;5c38   ; BIOS GTTRIG - Returns current trigger status
L_5C3B:
	ld (0f892h),a		;5c3b
	ret			;5c3e

; ----------------------------------------------------------------------
; DATOS restos_de_montaje: 0x3B bytes que no ejecuta nadie. Los tres primeros
;   son un `jp 0x401F` suelto y los 0x38 siguientes son copia EXACTA de
;   0x5BC2-0x5BF9 (comprobado byte a byte), el principio de la rutina de
;   llegada. La copia se corta a mitad. El mismo artefacto sale al final del
;   cargador y al final de la primera parte.
;   0x5c3f..0x5c7a  (59 bytes)
DATA_restos_de_montaje:
	defb 0c3h,01fh,040h,03ah,0deh,0f8h,0feh,0ffh	; 5c3f  ..@:....
	defb 0c0h,03eh,001h,0cdh,0b1h,057h,03eh,002h	; 5c47  .>...W>.
	defb 0cdh,05fh,000h,0cdh,089h,058h,021h,058h	; 5c4f  ._...X!X
	defb 0b3h,011h,000h,018h,001h,000h,003h,0cdh	; 5c57  ........
	defb 05ch,000h,021h,09ch,0cch,022h,07fh,0f8h	; 5c5f  \.!.."..
	defb 021h,046h,018h,022h,081h,0f8h,02ah,07fh	; 5c67  !F."..*.
	defb 0f8h,0edh,05bh,081h,0f8h,001h,003h,000h	; 5c6f  ..[.....
	defb 0cdh,05ch,000h	; 5c77

; ----------------------------------------------------------------------
; DATOS relleno_de_bloque: Los 1926 bytes que sobran del trozo de 0x2400, y
;   que ninguna instruccion del programa lee. No son basura al azar: llevan un
;   patron de ocho, cuatro bytes de {0x1F, 0x8F, 0x9F, 0xBF, 0xDF, 0xFF} y
;   cuatro de {0x00, 0x20, 0x40, 0x60}, o sea que el nibble bajo es siempre 0
;   o F y solo cambia el alto (medido: 964 bytes acaban en F y 962 en 0). Esa
;   forma es la de una tabla de COLORES de SCREEN 2 -tinta variable sobre
;   fondo blanco o transparente-, y la cola de 0xCCD8 del trozo alto lleva el
;   mismo patron. Pero la medida NO lo confirma: aqui el nibble bajo es 0 o F
;   en el 100 % de los bytes, y en las tablas de color de este mismo juego eso
;   solo pasa entre el 0 % y el 36,5 % de las veces (colores_comunes 12,5,
;   pantalla_1_colores 0,0, pantalla_4_colores 4,4, fuente_barco_colores 6,3,
;   pantalla_3_colores 36,5). La unica tabla de la cinta con esta forma es la
;   de la pantalla de carga, que es tinta sobre blanco y da el 98,4 %.
;   Dibujados como patrones no sale ningun dibujo, solo barras. Tampoco es la
;   memoria que dejo la primera parte: en estas mismas direcciones solo
;   coincide el 27,5 % de los bytes, y el fondo de coincidencia entre los dos
;   programas es del 2,3 %. Y hay una medida que descarta la tabla de colores
;   del todo: los grupos de ocho NO estan alineados a 8. Barriendo las ocho
;   fases con la regla "las cuatro primeras acaban en F y las cuatro ultimas
;   en 0", se cumple en el 100 % de los bytes empezando en 0x5C7A y solo en el
;   50 % empezando en la direccion 8-alineada 0x5C80; o sea que los registros
;   caen en direcciones con resto 2 al dividir por 8. Una tabla de colores de
;   SCREEN 2 esta alineada a 8 por construccion (base + baldosa*8), asi que
;   esto no lo es. Las otras dos colas de la cinta llevan la MISMA fase
;   -0xCCDA en el trozo alto y 0x5FFA en la primera parte, las dos al 100 %-,
;   lo que dice que las tres salen del mismo sitio y no es casualidad. Tampoco
;   estaba en pantalla: contra los dos volcados de VRAM de openMSX (16 KB cada
;   uno) no hay una sola coincidencia de 32 bytes. Ni tiene eco en el resto de
;   la cinta: buscando ventanas de 24 bytes en los cinco listados, esta cola
;   no aparece fuera de si misma. Que es exactamente queda como pregunta
;   abierta; la pista viva es ese desfase de dos bytes, que sugiere registros
;   de ocho con dos bytes de cabecera delante.
;   0x5c7a..0x6400  (1926 bytes)
DATA_relleno_de_bloque:
	defb 0dfh,09fh,0ffh,0dfh,040h,000h,000h,040h	; 5c7a  ....@..@
	defb 0dfh,0dfh,0bfh,09fh,020h,000h,020h,000h	; 5c82  .... . .
	defb 0bfh,09fh,0bfh,09fh,020h,000h,020h,000h	; 5c8a  .... . .
	defb 0bfh,09fh,0bfh,09fh,020h,000h,020h,000h	; 5c92  .... . .
	defb 0bfh,09fh,0bfh,09fh,020h,000h,000h,000h	; 5c9a  .... ...
	defb 0bfh,09fh,09fh,0ffh,040h,000h,020h,040h	; 5ca2  ....@. @
	defb 0dfh,0dfh,0bfh,0dfh,040h,000h,000h,040h	; 5caa  ....@..@
	defb 09fh,09fh,09fh,0bfh,020h,020h,000h,000h	; 5cb2  ....  ..
	defb 09fh,0ffh,0ffh,09fh,040h,040h,000h,000h	; 5cba  ....@@..
	defb 0dfh,0dfh,09fh,09fh,040h,040h,000h,000h	; 5cc2  ....@@..
	defb 0dfh,0dfh,0dfh,09fh,040h,040h,000h,000h	; 5cca  ....@@..
	defb 0dfh,0dfh,09fh,09fh,000h,040h,040h,000h	; 5cd2  .....@@.
	defb 0dfh,0dfh,09fh,09fh,040h,040h,000h,000h	; 5cda  ....@@..
	defb 0dfh,0dfh,09fh,09fh,040h,040h,000h,000h	; 5ce2  ....@@..
	defb 0dfh,0dfh,0dfh,09fh,040h,040h,000h,040h	; 5cea  ....@@.@
	defb 09fh,09fh,0ffh,0bfh,020h,000h,000h,060h	; 5cf2  .... ..`
	defb 0ffh,0ffh,09fh,09fh,040h,000h,000h,000h	; 5cfa  ....@...
	defb 0bfh,09fh,0dfh,09fh,040h,040h,000h,000h	; 5d02  ....@@..
	defb 0bfh,09fh,09fh,09fh,000h,000h,000h,000h	; 5d0a  ........
	defb 0bfh,09fh,09fh,09fh,020h,000h,000h,000h	; 5d12  .... ...
	defb 0bfh,09fh,0dfh,09fh,040h,000h,000h,000h	; 5d1a  ....@...
	defb 0bfh,09fh,0dfh,09fh,000h,000h,000h,000h	; 5d22  ........
	defb 0bfh,09fh,09fh,09fh,000h,000h,000h,020h	; 5d2a  ....... 
	defb 09fh,0ffh,0ffh,0bfh,020h,020h,000h,000h	; 5d32  ....  ..
	defb 0ffh,0dfh,0bfh,0dfh,040h,000h,020h,040h	; 5d3a  ....@. @
	defb 0dfh,0dfh,0bfh,0dfh,000h,040h,000h,040h	; 5d42  .....@.@
	defb 0dfh,0dfh,0bfh,0dfh,040h,000h,000h,040h	; 5d4a  ....@..@
	defb 0dfh,0dfh,0bfh,0dfh,000h,040h,020h,040h	; 5d52  .....@ @
	defb 0dfh,0dfh,0bfh,0dfh,040h,000h,020h,040h	; 5d5a  ....@. @
	defb 0dfh,0dfh,0bfh,0dfh,040h,000h,020h,040h	; 5d62  ....@. @
	defb 0dfh,0dfh,0bfh,0dfh,000h,000h,000h,000h	; 5d6a  ........
	defb 0ffh,0ffh,0ffh,0bfh,020h,000h,000h,000h	; 5d72  .... ...
	defb 0dfh,0dfh,09fh,09fh,040h,040h,000h,000h	; 5d7a  ....@@..
	defb 0dfh,0ffh,09fh,09fh,040h,000h,000h,000h	; 5d82  ....@...
	defb 0dfh,0dfh,09fh,0dfh,000h,000h,000h,000h	; 5d8a  ........
	defb 09fh,0dfh,09fh,09fh,040h,000h,000h,000h	; 5d92  ....@...
	defb 0dfh,0dfh,0dfh,09fh,040h,040h,000h,000h	; 5d9a  ....@@..
	defb 0dfh,0ffh,09fh,09fh,000h,040h,000h,000h	; 5da2  .....@..
	defb 0dfh,0dfh,09fh,0dfh,000h,040h,000h,000h	; 5daa  .....@..
	defb 09fh,09fh,0ffh,0bfh,020h,000h,000h,000h	; 5db2  .... ...
	defb 0bfh,09fh,09fh,09fh,040h,000h,000h,000h	; 5dba  ....@...
	defb 0dfh,0dfh,09fh,0dfh,020h,000h,000h,000h	; 5dc2  .... ...
	defb 0dfh,09fh,09fh,09fh,020h,000h,000h,000h	; 5dca  .... ...
	defb 0dfh,09fh,0bfh,09fh,000h,000h,000h,000h	; 5dd2  ........
	defb 0bfh,09fh,09fh,09fh,000h,000h,000h,000h	; 5dda  ........
	defb 0dfh,0dfh,09fh,09fh,020h,000h,000h,000h	; 5de2  .... ...
	defb 0dfh,09fh,09fh,09fh,000h,000h,000h,000h	; 5dea  ........
	defb 0dfh,09fh,09fh,09fh,000h,000h,000h,000h	; 5df2  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,060h	; 5dfa  .......`
	defb 0ffh,0ffh,09fh,09fh,000h,000h,000h,000h	; 5e02  ........
	defb 09fh,09fh,09fh,0ffh,060h,000h,000h,000h	; 5e0a  ....`...
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5e12  ........
	defb 09fh,09fh,0bfh,09fh,000h,000h,000h,000h	; 5e1a  ........
	defb 09fh,0dfh,09fh,09fh,000h,000h,000h,000h	; 5e22  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,040h	; 5e2a  .......@
	defb 0bfh,0bfh,09fh,09fh,000h,000h,000h,000h	; 5e32  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5e3a  ........
	defb 0ffh,0bfh,09fh,09fh,000h,000h,000h,000h	; 5e42  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5e4a  ........
	defb 0dfh,0ffh,09fh,09fh,000h,000h,000h,000h	; 5e52  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5e5a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5e62  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5e6a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,060h	; 5e72  .......`
	defb 0bfh,0bfh,0bfh,09fh,000h,000h,000h,060h	; 5e7a  .......`
	defb 09fh,09fh,0bfh,0ffh,000h,000h,020h,020h	; 5e82  ......  
	defb 0ffh,0ffh,0ffh,0bfh,060h,000h,040h,060h	; 5e8a  ....`.@`
	defb 0ffh,0ffh,0ffh,09fh,000h,000h,000h,000h	; 5e92  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5e9a  ........
	defb 09fh,09fh,09fh,09fh,040h,000h,040h,000h	; 5ea2  ....@.@.
	defb 09fh,09fh,09fh,0dfh,000h,000h,000h,000h	; 5eaa  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5eb2  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,020h	; 5eba  ....... 
	defb 09fh,09fh,09fh,09fh,020h,000h,000h,000h	; 5ec2  .... ...
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5eca  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5ed2  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5eda  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5ee2  ........
	defb 09fh,09fh,09fh,09fh,000h,040h,000h,020h	; 5eea  .....@. 
	defb 0ffh,0ffh,0ffh,09fh,000h,000h,000h,060h	; 5ef2  .......`
	defb 0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h	; 5efa  ........
	defb 09fh,0ffh,0ffh,09fh,000h,000h,000h,000h	; 5f02  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5f0a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5f12  ........
	defb 09fh,09fh,09fh,09fh,020h,000h,060h,060h	; 5f1a  .... .``
	defb 0ffh,0bfh,09fh,0ffh,020h,040h,060h,060h	; 5f22  .... @``
	defb 0ffh,0ffh,0ffh,0bfh,000h,000h,000h,000h	; 5f2a  ........
	defb 09fh,09fh,09fh,0bfh,000h,000h,020h,020h	; 5f32  ......  
	defb 09fh,09fh,0bfh,09fh,000h,000h,000h,000h	; 5f3a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5f42  ........
	defb 08fh,09fh,0bfh,0bfh,000h,000h,000h,000h	; 5f4a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5f52  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5f5a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,060h	; 5f62  .......`
	defb 0ffh,0ffh,09fh,09fh,000h,000h,000h,000h	; 5f6a  ........
	defb 0ffh,0ffh,0ffh,09fh,000h,000h,000h,000h	; 5f72  ........
	defb 09fh,0ffh,0ffh,09fh,000h,000h,000h,000h	; 5f7a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5f82  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5f8a  ........
	defb 09fh,09fh,09fh,0ffh,060h,020h,060h,060h	; 5f92  ....` ``
	defb 0ffh,09fh,09fh,0ffh,060h,020h,000h,060h	; 5f9a  ....` .`
	defb 0ffh,0ffh,0ffh,09fh,000h,000h,000h,000h	; 5fa2  ........
	defb 09fh,09fh,09fh,09fh,000h,020h,060h,060h	; 5faa  ..... ``
	defb 09fh,09fh,0bfh,09fh,000h,000h,000h,000h	; 5fb2  ........
	defb 09fh,0bfh,09fh,09fh,000h,000h,000h,000h	; 5fba  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5fc2  ........
	defb 09fh,0bfh,0bfh,09fh,000h,000h,000h,000h	; 5fca  ........
	defb 0bfh,09fh,09fh,09fh,000h,000h,000h,000h	; 5fd2  ........
	defb 0bfh,09fh,09fh,09fh,000h,000h,000h,000h	; 5fda  ........
	defb 0ffh,0ffh,0bfh,09fh,000h,000h,000h,060h	; 5fe2  .......`
	defb 0ffh,09fh,0ffh,09fh,000h,000h,000h,000h	; 5fea  ........
	defb 09fh,0ffh,0bfh,0dfh,000h,000h,000h,000h	; 5ff2  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 5ffa  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 6002  ........
	defb 09fh,09fh,09fh,0ffh,060h,040h,020h,060h	; 600a  ....`@ `
	defb 0ffh,0bfh,0dfh,0bfh,020h,000h,000h,000h	; 6012  .... ...
	defb 0ffh,0ffh,0ffh,09fh,020h,000h,000h,000h	; 601a  .... ...
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 6022  ........
	defb 09fh,09fh,09fh,09fh,040h,020h,000h,000h	; 602a  ....@ ..
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 6032  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 603a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 6042  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 604a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,040h	; 6052  .......@
	defb 0ffh,0ffh,0ffh,09fh,000h,000h,000h,040h	; 605a  .......@
	defb 0ffh,0ffh,09fh,09fh,000h,000h,000h,000h	; 6062  ........
	defb 09fh,09fh,0ffh,09fh,000h,000h,000h,000h	; 606a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 6072  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 607a  ........
	defb 09fh,09fh,09fh,0ffh,060h,000h,040h,060h	; 6082  ....`.@`
	defb 0ffh,0ffh,09fh,0ffh,060h,000h,040h,060h	; 608a  ....`.@`
	defb 0ffh,0ffh,0ffh,09fh,000h,000h,000h,000h	; 6092  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 609a  ........
	defb 09fh,09fh,09fh,09fh,000h,040h,040h,000h	; 60a2  .....@@.
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 60aa  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 60b2  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 60ba  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 60c2  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,060h,060h	; 60ca  ......``
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,040h	; 60d2  .......@
	defb 0ffh,0ffh,09fh,09fh,000h,000h,000h,040h	; 60da  .......@
	defb 0dfh,0dfh,0ffh,09fh,000h,000h,000h,000h	; 60e2  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 60ea  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 60f2  ........
	defb 09fh,0dfh,09fh,0ffh,020h,000h,000h,020h	; 60fa  .... .. 
	defb 0bfh,0bfh,09fh,0ffh,060h,040h,060h,060h	; 6102  ....`@``
	defb 0ffh,0ffh,0ffh,09fh,000h,000h,000h,000h	; 610a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,020h,000h	; 6112  ...... .
	defb 0bfh,09fh,09fh,09fh,000h,000h,000h,000h	; 611a  ........
	defb 09fh,09fh,0bfh,09fh,000h,000h,000h,000h	; 6122  ........
	defb 0ffh,09fh,09fh,09fh,000h,000h,000h,000h	; 612a  ........
	defb 09fh,09fh,09fh,0bfh,000h,000h,000h,000h	; 6132  ........
	defb 09fh,09fh,0bfh,09fh,000h,000h,000h,000h	; 613a  ........
	defb 09fh,09fh,09fh,09fh,000h,040h,060h,060h	; 6142  .....@``
	defb 0bfh,09fh,09fh,0bfh,000h,000h,000h,000h	; 614a  ........
	defb 0bfh,0ffh,0ffh,0dfh,040h,040h,000h,040h	; 6152  ....@@.@
	defb 0dfh,0dfh,0dfh,0dfh,040h,040h,040h,040h	; 615a  ....@@@@
	defb 0dfh,0dfh,0dfh,09fh,000h,000h,000h,000h	; 6162  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 616a  ........
	defb 09fh,09fh,09fh,0bfh,020h,020h,020h,020h	; 6172  ....    
	defb 0bfh,0bfh,0bfh,0bfh,020h,020h,020h,020h	; 617a  ....    
	defb 0bfh,0bfh,0bfh,09fh,000h,000h,000h,000h	; 6182  ........
	defb 09fh,0bfh,0dfh,09fh,020h,000h,020h,020h	; 618a  .... .  
	defb 09fh,09fh,0bfh,0bfh,000h,000h,000h,000h	; 6192  ........
	defb 09fh,0dfh,0bfh,09fh,000h,000h,000h,000h	; 619a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 61a2  ........
	defb 09fh,09fh,0bfh,0bfh,000h,000h,000h,000h	; 61aa  ........
	defb 09fh,0dfh,0bfh,09fh,000h,000h,000h,000h	; 61b2  ........
	defb 01fh,09fh,09fh,09fh,000h,000h,060h,060h	; 61ba  ......``
	defb 0ffh,0ffh,0dfh,09fh,000h,000h,000h,000h	; 61c2  ........
	defb 0ffh,0ffh,0ffh,01fh,000h,000h,000h,000h	; 61ca  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 61d2  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 61da  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 61e2  ........
	defb 09fh,0dfh,09fh,0ffh,060h,020h,040h,060h	; 61ea  ....` @`
	defb 0ffh,0ffh,0ffh,0ffh,060h,060h,060h,020h	; 61f2  ....``` 
	defb 0ffh,0ffh,0ffh,09fh,000h,000h,000h,000h	; 61fa  ........
	defb 09fh,09fh,09fh,09fh,020h,000h,000h,000h	; 6202  .... ...
	defb 09fh,09fh,09fh,0bfh,000h,000h,000h,000h	; 620a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 6212  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 621a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 6222  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 622a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,020h	; 6232  ....... 
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 623a  ........
	defb 0ffh,0ffh,0ffh,09fh,000h,000h,000h,000h	; 6242  ........
	defb 0dfh,09fh,0dfh,09fh,000h,000h,000h,000h	; 624a  ........
	defb 0dfh,09fh,0dfh,09fh,000h,000h,000h,000h	; 6252  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 625a  ........
	defb 09fh,09fh,09fh,0ffh,000h,000h,000h,020h	; 6262  ....... 
	defb 0bfh,0ffh,0bfh,0ffh,020h,000h,020h,040h	; 626a  .... . @
	defb 0bfh,0ffh,0bfh,09fh,000h,000h,000h,000h	; 6272  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 627a  ........
	defb 09fh,09fh,09fh,0bfh,000h,000h,000h,000h	; 6282  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 628a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 6292  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 629a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 62a2  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 62aa  ........
	defb 0bfh,0bfh,0dfh,09fh,000h,000h,000h,000h	; 62b2  ........
	defb 09fh,0ffh,0ffh,0ffh,040h,000h,000h,060h	; 62ba  ....@..`
	defb 0ffh,0ffh,0ffh,0ffh,060h,000h,000h,000h	; 62c2  ....`...
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 62ca  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 62d2  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 62da  ........
	defb 09fh,09fh,09fh,09fh,000h,020h,000h,020h	; 62e2  ..... . 
	defb 0ffh,0ffh,0ffh,0bfh,000h,000h,000h,000h	; 62ea  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,020h	; 62f2  ....... 
	defb 0bfh,09fh,09fh,0ffh,020h,000h,000h,000h	; 62fa  .... ...
	defb 09fh,09fh,09fh,0bfh,000h,000h,000h,000h	; 6302  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 630a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 6312  ........
	defb 09fh,09fh,0ffh,09fh,000h,000h,000h,000h	; 631a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,040h	; 6322  .......@
	defb 0ffh,0ffh,0dfh,0ffh,000h,000h,000h,000h	; 632a  ........
	defb 09fh,09fh,0ffh,0ffh,020h,000h,000h,000h	; 6332  .... ...
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 633a  ........
	defb 09fh,0bfh,09fh,09fh,000h,000h,000h,000h	; 6342  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 634a  ........
	defb 09fh,09fh,09fh,09fh,000h,020h,000h,060h	; 6352  ..... .`
	defb 0ffh,0ffh,0ffh,0ffh,060h,040h,020h,060h	; 635a  ....`@ `
	defb 0ffh,0ffh,0ffh,09fh,000h,000h,020h,020h	; 6362  ......  
	defb 09fh,09fh,09fh,09fh,000h,020h,000h,000h	; 636a  ..... ..
	defb 09fh,09fh,09fh,0ffh,060h,020h,000h,000h	; 6372  ....` ..
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 637a  ........
	defb 09fh,09fh,0bfh,09fh,000h,000h,000h,000h	; 6382  ........
	defb 09fh,0bfh,0bfh,09fh,000h,000h,000h,000h	; 638a  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 6392  ........
	defb 09fh,09fh,09fh,0bfh,000h,000h,000h,040h	; 639a  .......@
	defb 09fh,0ffh,0ffh,09fh,000h,000h,000h,000h	; 63a2  ........
	defb 09fh,0dfh,0ffh,0ffh,060h,020h,000h,060h	; 63aa  ....` .`
	defb 0ffh,0ffh,0ffh,0ffh,020h,000h,000h,000h	; 63b2  .... ...
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 63ba  ........
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 63c2  ........
	defb 01fh,09fh,09fh,09fh,000h,000h,020h,000h	; 63ca  ...... .
	defb 09fh,09fh,09fh,09fh,040h,000h,020h,060h	; 63d2  ....@. `
	defb 0ffh,0ffh,0ffh,09fh,000h,000h,000h,000h	; 63da  ........
	defb 09fh,0bfh,0bfh,0bfh,000h,000h,000h,000h	; 63e2  ........
	defb 09fh,09fh,09fh,0bfh,060h,000h,000h,000h	; 63ea  ....`...
	defb 09fh,09fh,09fh,09fh,000h,000h,000h,000h	; 63f2  ........
	defb 09fh,09fh,09fh,09fh,000h,000h	; 63fa
