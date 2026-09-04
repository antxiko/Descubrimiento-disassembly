; ==========================================================================
; EL DESCUBRIMIENTO DE AMERICA - MSX - primera parte: el programa
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS firma: Los caracteres 'A' y 'B'. Ninguna instruccion los lee; la unica
;   pista de que son firma y no basura es que los DOS bloques sin cabecera de
;   la cinta empiezan igual.
;   0x4000..0x4002  (2 bytes)

; ----------------------------------------------------------------------
; ==========================================================
; EL DESCUBRIMIENTO DE AMERICA - primera parte, el programa
; ==========================================================
; La cinta trae este bloque SIN cabecera: no lo lee la BIOS,
; lo lee a mano el cargador de 0xD369, y lo reparte en dos
; trozos: 0x2400 bytes aqui, a 0x4000, y 0x5300 bytes a
; 0x8000. Este es el bajo, y es codigo casi de punta a punta.
;
; La primera parte son OCHO pantallas por las que hay que
; pasar antes de zarpar: el puerto de Palos, la taberna, el
; astillero, el monasterio, la corte... La variable que manda
; es 0xF893, el numero de pantalla, y la rutina que carga cada
; una es la de 0x4604.
;
; Al terminar, en 0x5CC2, salta a (0xD300) -o sea a 0xD369- y
; el cargador se lee de la cinta la segunda parte.
; ----------------------------------------------------------------------
DATA_firma:
	defb 041h,042h	; 4000

; ----------------------------------------------------------------------
; DATOS punto_de_entrada: La palabra 0x4202: el cargador la lee en 0xD3AD con
;   `ld hl,(0x4002)` y salta ahi metiendola en la pila. En la segunda parte
;   esta misma palabra vale 0x401F.
;   0x4002..0x4004  (2 bytes)
DATA_punto_de_entrada:
	defw 04202h	; 4002  -> principal

; ----------------------------------------------------------------------
; DATOS hueco_de_cabecera: Doce ceros entre la cabecera y el codigo. No los
;   toca nadie.
;   0x4004..0x4010  (12 bytes)
DATA_hueco_de_cabecera:
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 4004  ............

; ======================================================================
; CODIGO 0x4010..0x5f9f  (8079 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; --- rutina de servicio: la VRAM entera de una vez -------
; Apaga la pantalla y vuelca 16 KB de 0x8000 a la VRAM
; completa. En este bloque no la llama nadie; aparece igual,
; byte a byte, al principio de la segunda parte.
; ----------------------------------------------------------------------
vuelca_vram_entera:		; Apaga la pantalla y copia 0x8000-0xBFFF a la VRAM
	call 00041h		;4010   ; BIOS DISSCR - Inhibits the screen display | DISSCR
	ld hl,08000h		;4013
	ld de,00000h		;4016
	ld bc,04000h		;4019
	jp 0005ch		;401c   ; BIOS LDIRVM - Block transfers to VRAM from memory | LDIRVM: 0x4000 bytes a partir de la direccion 0 de VRAM

; ----------------------------------------------------------------------
; ==========================================================
; EL REPRODUCTOR DE MUSICA
; ==========================================================
; Suena colgado de H.KEYI (0xFD9F), el gancho que la BIOS
; ejecuta en cada interrupcion de barrido antes de leer el
; teclado: cincuenta veces por segundo en una maquina europea.
;
; El estado son catorce bytes seguidos, de 0xF8CB a 0xF8D8:
;
; 0xF8CB  contador de compas (cuenta hasta 6)
; 0xF8CC  peticion de silencio (8 y 9 mientras se apaga)
; 0xF8CD  marca de "el canal A se ha quedado sin partitura"
; 0xF8CE  canal A: puntero de partitura (2 bytes) y duracion
; 0xF8D1  canal B: lo mismo
; 0xF8D4  canal C: lo mismo
; 0xF8D7  puntero a la entrada de melodia que se esta tocando
; 0xF8D9  cursor con el que se recorren los tres canales
;
; Cada canal son TRES bytes -puntero de dos y duracion de uno-,
; y por eso el cursor de 0x4181 avanza de tres en tres: la
; misma rutina sirve para los tres canales sin una sola tabla.
; ----------------------------------------------------------------------
inicia_musica:		; Borra el estado del reproductor y engancha la interrupcion
	ld hl,0f8cbh		;401f   ; HL: primer byte del estado del reproductor
	ld de,0f8d9h		;4022   ; DE: el ultimo, para el DCOMPR del bucle
L_4025:
	xor a			;4025   ; --- borra de 0xF8CB a 0xF8D8, catorce bytes ---
	ld (hl),a			;4026
	inc hl			;4027
	rst 20h			;4028   ; DCOMPR compara HL con DE
	jp nz,L_4025		;4029
	ld a,00bh		;402c   ; 0x0B es el silencio en este reproductor...
	ld (0f8ceh),a		;402e   ; ...y se le pone a los tres canales de golpe
	ld (0f8d1h),a		;4031
	ld (0f8d4h),a		;4034
	di			;4037   ; el gancho se toca con las interrupciones cerradas
	ld hl,0fd9fh		;4038   ; H.KEYI, el gancho de teclado de la BIOS...
	ld a,0c3h		;403b   ; ...pasa a ser un JP...
	ld (hl),a			;403d
	ld hl,suena		;403e   ; ...al reproductor de aqui abajo
	ld (0fda0h),hl		;4041   ; los dos bytes de detras del 0xC3 son el destino del salto
	ei			;4044   ; y ya puede sonar
	ret			;4045

; ----------------------------------------------------------------------
; --- lo que suena en cada interrupcion --------------------
; ----------------------------------------------------------------------
suena:		; Manejador de H.KEYI: una nota de cada canal por interrupcion
	di			;4046   ; la BIOS entra aqui con las interrupciones abiertas
	push af			;4047   ; el gancho es codigo de sistema: hay que devolver los registros intactos
	push hl			;4048
	push de			;4049
	push bc			;404a
	ld hl,0f8cch		;404b   ; 0xF8CC: si vale 8 o mas, alguien ha mandado callar la musica
	ld a,(hl)			;404e
	cp 008h		;404f
	jp c,toca		;4051   ; mientras valga menos de 8, a tocar
	call avanza_contador		;4054   ; al mandar callar se cuenta 8, 9 y vuelta a 0
	cp 00ah		;4057   ; en la decima vuelta se cierra el ciclo
	jp nz,L_405E		;4059
	xor a			;405c
	ld (hl),a			;405d
L_405E:
	di			;405e
	call 00090h		;405f   ; BIOS GICINI - Initialises PSG and sets initial value for the PLAY statement | GICINI deja el PSG mudo y las tablas del PLAY como estaban
	di			;4062
L_4063:
	pop bc			;4063   ; --- salida comun: los registros como estaban ---
	pop de			;4064
	pop hl			;4065
	pop af			;4066
	ei			;4067   ; la BIOS espera volver con las interrupciones abiertas
	ret			;4068

; ----------------------------------------------------------------------
; --- los catorce registros del PSG, uno por uno -----------
; ----------------------------------------------------------------------
toca:		; Monta los catorce registros del PSG con la nota de cada canal
	call primer_canal		;4069   ; el primer byte de partitura del canal A
	ld e,03fh		;406c   ; 0x3F: los tres tonos y los tres ruidos callados
	cp 000h		;406e   ; si el byte del canal A es 0, el canal no suena
	jp z,L_4077		;4070
	ld a,e			;4073
	res 0,a		;4074   ; y si no lo es, se abre el tono del canal A (bit 0 a cero)
	ld e,a			;4076
L_4077:
	call siguiente_canal		;4077   ; lo mismo para el canal B...
	cp 000h		;407a
	jp z,L_4083		;407c
	ld a,e			;407f
	res 1,a		;4080   ; ...bit 1
	ld e,a			;4082
L_4083:
	call siguiente_canal		;4083   ; ...y para el C
	cp 000h		;4086
	jp z,L_408F		;4088
	ld a,e			;408b
	res 2,a		;408c   ; bit 2
	ld e,a			;408e
L_408F:
	ld a,007h		;408f   ; registro 7: la mezcla que se acaba de calcular
	call escribe_psg		;4091
	ld a,00bh		;4094   ; registros 11 y 12: periodo del envolvente, a 0xFFFF
	ld e,0ffh		;4096
	call escribe_psg		;4098
	inc a			;409b
	call escribe_psg		;409c
	ld a,008h		;409f   ; registros 8, 9 y 10: el volumen de los tres canales
	ld e,a			;40a1
	call escribe_psg		;40a2
	inc a			;40a5
	call escribe_psg		;40a6
	inc a			;40a9
	call escribe_psg		;40aa
	call primer_canal		;40ad   ; siguiente byte del canal A: el nibble bajo es el tono fino
	and 00fh		;40b0
	ld e,a			;40b2
	ld a,001h		;40b3   ; registro 1: los cuatro bits altos del tono del canal A
	call escribe_psg		;40b5
	inc bc			;40b8   ; el byte siguiente de la partitura es el tono grueso
	ld a,(bc)			;40b9
	ld e,a			;40ba
	xor a			;40bb   ; registro 0
	call escribe_psg		;40bc
	call siguiente_canal		;40bf   ; ahora el canal B: registros 3 y 2
	and 00fh		;40c2
	ld e,a			;40c4
	ld a,003h		;40c5
	call escribe_psg		;40c7
	inc bc			;40ca
	ld a,(bc)			;40cb
	ld e,a			;40cc
	ld a,002h		;40cd
	call escribe_psg		;40cf
	call siguiente_canal		;40d2   ; y el canal C: registros 5 y 4
	and 00fh		;40d5
	ld e,a			;40d7
	ld a,005h		;40d8
	call escribe_psg		;40da
	inc bc			;40dd
	ld a,(bc)			;40de
	ld e,a			;40df
	ld a,004h		;40e0
	call escribe_psg		;40e2
	ld hl,0f8cbh		;40e5   ; 0xF8CB: un compas mas
	call avanza_contador		;40e8
	cp 006h		;40eb   ; a los seis compases toca mirar si hay cambio de melodia
	jp nz,L_4063		;40ed
	xor a			;40f0
	ld (hl),a			;40f1
	ld hl,0f8d0h		;40f2   ; avanza la duracion de los tres canales, uno de tres en tres
	call avanza_contador		;40f5
	inc hl			;40f8
	inc hl			;40f9
	inc hl			;40fa
	call avanza_contador		;40fb
	inc hl			;40fe
	inc hl			;40ff
	inc hl			;4100
	call avanza_contador		;4101
	call primer_canal		;4104   ; lee el byte de duracion del canal A
	ld e,a			;4107
	cp 000h		;4108   ; si es cero, la melodia se ha acabado
	jp z,L_4190		;410a
	ld a,e			;410d
	call nibble_alto		;410e   ; el nibble alto es cuantos compases dura la nota
	ld a,(0f8d0h)		;4111   ; 0xF8D0 lleva los compases ya gastados
	cp e			;4114
	jp c,L_4124		;4115   ; si no ha llegado, la nota sigue sonando
	ld hl,(0f8ceh)		;4118   ; y si ha llegado, el puntero del canal A avanza dos bytes...
	inc hl			;411b
	inc hl			;411c
	ld (0f8ceh),hl		;411d
	xor a			;4120   ; ...y el contador de compases se pone a cero
	ld (0f8d0h),a		;4121
L_4124:
	call siguiente_canal		;4124   ; --- lo mismo para el canal B ---
	ld e,a			;4127   ; el byte de duracion del canal B
	cp 000h		;4128
	jp z,L_4198		;412a   ; si es cero, ese canal ya no tiene nada
	ld a,e			;412d
	call nibble_alto		;412e   ; los compases que dura la nota
	ld a,(0f8d3h)		;4131   ; y los que lleva sonando
	cp e			;4134
	jp c,L_4144		;4135
	ld hl,(0f8d1h)		;4138   ; el puntero del canal B avanza dos bytes
	inc hl			;413b
	inc hl			;413c
	ld (0f8d1h),hl		;413d
	xor a			;4140
	ld (0f8d3h),a		;4141
L_4144:
	call siguiente_canal		;4144   ; --- y para el canal C ---
	ld e,a			;4147   ; el byte de duracion del canal C
	cp 000h		;4148
	jp z,L_4063		;414a   ; si es cero, se acabo la vuelta
	ld a,e			;414d
	call nibble_alto		;414e
	ld a,(0f8d6h)		;4151   ; los compases gastados del canal C
	cp e			;4154
	jp c,L_4063		;4155
	ld hl,(0f8d4h)		;4158   ; el puntero del canal C avanza dos bytes
	inc hl			;415b
	inc hl			;415c
	ld (0f8d4h),hl		;415d
	xor a			;4160
	ld (0f8d6h),a		;4161   ; y su contador de compases, a cero
	jp L_4063		;4164
escribe_psg:		; WRTPSG con las interrupciones cerradas
	di			;4167   ; WRTPSG las abre al salir, y aqui estamos dentro de un gancho
	call 00093h		;4168   ; BIOS WRTPSG - Writes data to PSG-register
	di			;416b
	ret			;416c
avanza_contador:		; (HL)++ y devuelve el valor nuevo
	ld a,(hl)			;416d
	inc a			;416e
	ld (hl),a			;416f
	ret			;4170
nibble_alto:		; A >> 4: los compases que dura la nota
	srl a		;4171   ; cuatro desplazamientos a la derecha...
	srl a		;4173
	srl a		;4175
	srl a		;4177
	ld e,a			;4179   ; ...y el resultado tambien en E
	ret			;417a
primer_canal:		; Pone el cursor en el canal A y lee su byte de partitura
	ld hl,0f8ceh		;417b   ; 0xF8CE es el primer canal...
	ld (0f8d9h),hl		;417e   ; ...y 0xF8D9 el cursor que va a recorrer los tres
siguiente_canal:		; Lee el byte de partitura del canal en curso y avanza tres
	ld hl,(0f8d9h)		;4181   ; el cursor apunta al puntero de partitura del canal
	ld a,(hl)			;4184   ; BC = ese puntero
	ld c,a			;4185
	inc hl			;4186
	ld a,(hl)			;4187
	ld b,a			;4188
	inc hl			;4189   ; tres bytes por canal: puntero (2) y duracion (1)
	inc hl			;418a
	ld (0f8d9h),hl		;418b
	ld a,(bc)			;418e   ; y devuelve el byte de partitura al que apunta
	ret			;418f
L_4190:
	ld a,0ffh		;4190   ; --- el canal A se ha quedado sin notas ---
	ld (0f8cdh),a		;4192   ; se anota en 0xF8CD y se sigue con los otros dos canales
	jp L_4124		;4195
L_4198:
	ld a,(0f8cdh)		;4198   ; --- el canal B tambien: entonces la melodia ha terminado ---
	cp 0ffh		;419b
	jp nz,L_4144		;419d
	xor a			;41a0
	ld (0f8cdh),a		;41a1
	call es_fin_de_lista		;41a4   ; si el puntero de melodia es 0x0000 no hay lista que seguir
	cp 000h		;41a7
	jp z,L_41BE		;41a9
L_41AC:
	ld hl,00000h		;41ac   ; y sin lista, silencio: los tres canales a 0x0B
	ld (0f8d7h),hl		;41af
	ld hl,0000bh		;41b2
	ld (0f8ceh),hl		;41b5
	ld (0f8d1h),hl		;41b8
	jp L_4144		;41bb
L_41BE:
	ld hl,(0f8d7h)		;41be   ; con lista, se pasa a la entrada siguiente, cuatro bytes mas alla
	inc hl			;41c1
	inc hl			;41c2
	inc hl			;41c3
	inc hl			;41c4
	ld (0f8d7h),hl		;41c5
	call es_fin_de_lista_hl		;41c8
	cp 001h		;41cb   ; si esa entrada es el 0x0000 del final, a callar
	jp z,L_41AC		;41cd
	call carga_melodia		;41d0
	jp L_4144		;41d3
carga_melodia:		; Copia los dos punteros de la melodia de (0xF8D7) a los canales
	ld hl,(0f8d7h)		;41d6   ; la entrada son cuatro bytes: canal A (2) y canal B (2)
	ld a,(hl)			;41d9
	ld (0f8ceh),a		;41da   ; byte bajo del puntero del canal A
	inc hl			;41dd
	ld a,(hl)			;41de
	ld (0f8cfh),a		;41df   ; byte alto
	inc hl			;41e2
	ld a,(hl)			;41e3
	ld (0f8d1h),a		;41e4   ; y los dos del canal B
	inc hl			;41e7
	ld a,(hl)			;41e8
	ld (0f8d2h),a		;41e9
	ret			;41ec
es_fin_de_lista:		; Devuelve 1 si la entrada de melodia de 0xF8D7 es 0x0000
	ld hl,0f8d7h		;41ed
es_fin_de_lista_hl:		; Igual, pero con HL ya puesto
	ld a,(hl)			;41f0   ; basta con mirar los dos bytes del puntero del canal A
	cp 000h		;41f1
	jp nz,L_4200		;41f3
	inc hl			;41f6
	ld a,(hl)			;41f7
	cp 000h		;41f8
	jp nz,L_4200		;41fa
	ld a,001h		;41fd   ; 1 = se acabo la lista
	ret			;41ff
L_4200:
	xor a			;4200   ; 0 = todavia hay melodia
	ret			;4201

; ----------------------------------------------------------------------
; ==========================================================
; ARRANQUE DE LA PRIMERA PARTE
; ==========================================================
; Monta la memoria, presenta el juego y entra en el bucle.
; Las variables del juego viven todas juntas de 0xF87F a
; 0xF91E, en la zona que el BASIC reserva para las extensiones
; de disco y que aqui no usa nadie. Las mas importantes:
;
; 0xF87F..0xF88E  los seis punteros de trabajo de los
; volcadores a VRAM
; 0xF893  numero de pantalla, de 0 a 7
; 0xF894  ultima direccion leida del mando
; 0xF89C  el estado del protagonista: elige que juego de
; sprites de 0x168 bytes se usa
; 0xF89D  columna por la que se recorta el mapa ancho
; 0xF89F  pasos dados en la aventura
; 0xF8A0  marcador
; 0xF8C4  ultima lectura del gatillo
; 0xF8C6  la pantalla que se esta tocando en la musica
; ----------------------------------------------------------------------
principal:		; Punto de entrada del bloque
	ld hl,0db88h		;4202   ; la pila, justo debajo de la zona de trabajo
	ld sp,hl			;4205
	xor a			;4206
	ld (0f8a5h),a		;4207   ; 0xF8A5: el contador de repeticiones de melodia, a cero
	ld a,(0c103h)		;420a   ; 0xC103 es un byte de los propios patrones, y hace de marca...
	cp 008h		;420d   ; ...si no vale 8, es que todavia no se han volteado
	call nz,voltea_los_patrones		;420f   ; y entonces se voltean, una sola vez por partida
	ld hl,0f87fh		;4212   ; HL: primera variable del juego
	ld de,0f91fh		;4215   ; DE: la ultima
L_4218:
	xor a			;4218   ; --- borra de 0xF87F a 0xF91E ---
	ld (hl),a			;4219
	inc hl			;421a
	rst 20h			;421b
	jr nz,L_4218		;421c
	ld a,0ffh		;421e   ; 0xF8C6 a 0xFF: asi la primera pantalla cuenta como cambio
	ld (0f8c6h),a		;4220
	ld hl,0c610h		;4223   ; las coordenadas de partida estan en 0xC610, dos por ficha
	ld (0f87fh),hl		;4226
	ld hl,0aafdh		;4229   ; y las fichas, a partir de 0xAAFD
L_422C:
	ld de,(0f87fh)		;422c   ; X de la ficha
	ld a,(de)			;4230
	ld (hl),a			;4231
	inc hl			;4232
	inc de			;4233
	ld a,(de)			;4234   ; Y de la ficha
	ld (hl),a			;4235
	inc de			;4236
	ld (0f87fh),de		;4237
	inc hl			;423b
	ld a,003h		;423c   ; el tercer byte, el estado, arranca en 3
	ld (hl),a			;423e
	inc hl			;423f
	xor a			;4240   ; el cuarto, el fotograma, en 0
	ld (hl),a			;4241
	ld de,00008h		;4242   ; y los siete restantes se dejan como esten
	add hl,de			;4245
	ld de,0ab29h		;4246   ; cuatro fichas de once bytes: de 0xAAFD a 0xAB29
	rst 20h			;4249
	jp nz,L_422C		;424a
	ld hl,097f5h		;424d   ; el mapa ancho vive en 0x97F5...
	ld (0f87fh),hl		;4250
	ld hl,0cbd7h		;4253   ; ...y su version intacta, en 0xCBD7
	ld (0f881h),hl		;4256
L_4259:
	ld hl,(0f881h)		;4259
	ld a,(hl)			;425c
	inc hl			;425d
	ld (0f881h),hl		;425e
	ld hl,(0f87fh)		;4261
	ld (hl),a			;4264
	inc hl			;4265
	ld (0f87fh),hl		;4266
	ld de,09874h		;4269   ; 0x9874: 0x7F bytes, las dos primeras filas y pico
	rst 20h			;426c
	jp nz,L_4259		;426d
	ld hl,093a6h		;4270   ; --- retoques sueltos sobre las pantallas ya cargadas ---
	ld de,0001fh		;4273   ; 0x1F: una fila de 32 baldosas menos una
	ld a,065h		;4276
	ld (hl),a			;4278
	inc hl			;4279
	ld a,0f4h		;427a
	ld (hl),a			;427c
	add hl,de			;427d
	ld a,0f7h		;427e
	ld (hl),a			;4280
	inc hl			;4281
	ld a,0f5h		;4282
	ld (hl),a			;4284
	add hl,de			;4285
	ld a,0f8h		;4286
	ld (hl),a			;4288
	inc hl			;4289
	ld a,0f6h		;428a
	ld (hl),a			;428c
	ld hl,0911ah		;428d
	ld a,0f7h		;4290
	ld (hl),a			;4292
	ld de,00020h		;4293
	add hl,de			;4296
	ld a,0f8h		;4297
	ld (hl),a			;4299
	add hl,de			;429a
	ld a,06ah		;429b
	ld (hl),a			;429d
	inc hl			;429e
	ld a,06ch		;429f
	ld (hl),a			;42a1
	inc hl			;42a2
	ld a,019h		;42a3
	ld (hl),a			;42a5
	inc hl			;42a6
	ld a,038h		;42a7
	ld (hl),a			;42a9
	ld hl,09406h		;42aa
	ld a,05eh		;42ad
	ld (hl),a			;42af
	inc hl			;42b0
	ld a,064h		;42b1
	ld (hl),a			;42b3
	ld hl,0f3e9h		;42b4   ; FORCLR: tinta 1
	ld a,001h		;42b7
	ld (hl),a			;42b9
	inc hl			;42ba
	ld a,00eh		;42bb   ; BAKCLR y BDRCLR: fondo y borde en 14
	ld (hl),a			;42bd
	inc hl			;42be
	ld (hl),a			;42bf
	call 00044h		;42c0   ; BIOS ENASCR - Displays the screen | ENASCR
	ld a,002h		;42c3   ; SCREEN 2
	call 0005fh		;42c5   ; BIOS CHGMOD - Switches to given screen mode
	ld hl,00118h		;42c8   ; destino en la tabla de patrones
	ld (0f87fh),hl		;42cb
	ld a,004h		;42ce   ; color del rotulo
	ld (0f881h),a		;42d0
	ld hl,00704h		;42d3   ; 0x0704: cuatro baldosas de ancho por siete de alto
	ld (0f883h),hl		;42d6
	ld hl,080e0h		;42d9   ; y el dibujo, en 0x80E0
	ld (0f885h),hl		;42dc
	call dibuja_rectangulo		;42df
	ld hl,00250h		;42e2   ; el segundo rotulo: a 0x0250, color 8, dos por cuatro
	ld (0f87fh),hl		;42e5
	ld a,008h		;42e8
	ld (0f881h),a		;42ea
	ld hl,00402h		;42ed
	ld (0f883h),hl		;42f0
	ld hl,081c0h		;42f3
	ld (0f885h),hl		;42f6
	call dibuja_rectangulo		;42f9
	ld hl,00560h		;42fc   ; el texto de la presentacion: empieza en la baldosa 0x0560
	ld (0f88dh),hl		;42ff
	ld hl,08200h		;4302   ; la cadena, en 0x8200
	ld (0f883h),hl		;4305
	call escribe_texto		;4308
	ld hl,00750h		;430b   ; el segundo bloque de texto, en la baldosa 0x0750
	ld (0f88dh),hl		;430e
	ld a,004h		;4311   ; cuatro tiempos de espera
	ld (0f887h),a		;4313
L_4316:
	call espera_un_rato		;4316   ; espera a que se agote la cuenta de 0xF887
	cp 000h		;4319
	jr nz,L_4316		;431b
	ld hl,01010h		;431d   ; tercer bloque, en 0x1010
	ld (0f88dh),hl		;4320
	ld a,004h		;4323
	ld (0f887h),a		;4325
L_4328:
	call espera_un_rato		;4328
	cp 000h		;432b
	jr nz,L_4328		;432d
	ld hl,010c0h		;432f   ; el ultimo rotulo: a 0x10C0, color 0x0C, cuatro por siete
	ld (0f87fh),hl		;4332
	ld a,00ch		;4335
	ld (0f881h),a		;4337
	ld hl,00704h		;433a
	ld (0f883h),hl		;433d
	ld hl,08000h		;4340
	ld (0f885h),hl		;4343
	call dibuja_rectangulo		;4346
	call toca_presentacion		;4349   ; arranca la melodia de la presentacion...
L_434C:
	call melodia_terminada		;434c   ; ...y espera a que termine
	jp nz,L_434C		;434f
	call toca_presentacion		;4352   ; la toca otra vez...
L_4355:
	call melodia_terminada		;4355   ; ...y al acabar, al juego
	jp nz,L_4355		;4358
	jp arranca_el_juego		;435b
toca_presentacion:		; Arranca la melodia cuya entrada esta en 0x82EF
	ld hl,082efh		;435e   ; 0x82EF: los dos punteros de la melodia de la presentacion
L_4361:
	ld (0f87fh),hl		;4361   ; el reproductor se reinicia entero
	call inicia_musica		;4364
	di			;4367   ; los punteros se cambian con la interrupcion cerrada
	ld hl,(0f87fh)		;4368
	ld (0f8d7h),hl		;436b
	call carga_melodia		;436e
	ei			;4371
	ret			;4372
melodia_terminada:		; Devuelve Z si el puntero de melodia se ha quedado a cero
	ld hl,(0f8d7h)		;4373   ; DCOMPR con 0x0000: el reproductor lo pone asi al acabar
	ld de,00000h		;4376
	jp 00020h		;4379   ; BIOS DCOMPR - Compares HL with DE
espera_un_rato:		; Una vuelta de la cuenta atras de 0xF887
	call escribe_texto		;437c   ; de paso escribe la linea de texto que toque
	call tic		;437f   ; dos pasos del contador lento por cada linea
	call tic		;4382
	ld a,(0f887h)		;4385   ; y uno de la cuenta atras
	dec a			;4388
	ld (0f887h),a		;4389
	ret			;438c
tic:		; 0xF88E++: el contador lento de la presentacion
	ld a,(0f88eh)		;438d
	inc a			;4390
	ld (0f88eh),a		;4391
	ret			;4394
escribe_texto:		; Escribe una cadena en la tabla de patrones, letra a letra
	ld a,001h		;4395   ; una baldosa por letra
	ld (0f881h),a		;4397
	ld hl,(0f88dh)		;439a   ; 0xF88D: la baldosa donde empieza la linea
	ld (0f87fh),hl		;439d
	call color_del_sitio		;43a0   ; calcula el color con el que se va a escribir
L_43A3:
	ld hl,(0f883h)		;43a3   ; --- una letra por vuelta ---
	ld a,(hl)			;43a6   ; el codigo de caracter
	ld (0f882h),a		;43a7
	cp 00dh		;43aa   ; 0x0D termina la linea
	jp z,siguiente_letra_texto		;43ac
	ld hl,01bbfh		;43af   ; 0x1BBF es CGTABL: la fuente de la ROM del BASIC
	ld de,00008h		;43b2
L_43B5:
	add hl,de			;43b5   ; ocho bytes por caracter: se salta uno a uno
	ld a,(0f882h)		;43b6
	dec a			;43b9
	ld (0f882h),a		;43ba
	cp 000h		;43bd
	jp nz,L_43B5		;43bf
	ld de,(0f87fh)		;43c2
	ld bc,00008h		;43c6   ; el patron de la letra, a la tabla de patrones
	call 0005ch		;43c9   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld bc,00008h		;43cc   ; y el color, ocho bytes iguales
	ld de,02000h		;43cf
	ld hl,(0f87fh)		;43d2
	add hl,de			;43d5
	ld a,(0f881h)		;43d6
	call 00056h		;43d9   ; BIOS FILVRM - Fills VRAM with value
	call siguiente_letra_texto		;43dc   ; pasa a la letra siguiente
	call siguiente_baldosa		;43df   ; y a la baldosa siguiente
	jp L_43A3		;43e2
siguiente_letra_texto:		; Adelanta un byte el puntero de la cadena
	ld hl,(0f883h)		;43e5
	inc hl			;43e8
	ld (0f883h),hl		;43e9
	ret			;43ec
siguiente_baldosa:		; Suma 8 al destino: la baldosa de al lado
	ld a,(0f87fh)		;43ed
	add a,008h		;43f0
	ld (0f87fh),a		;43f2
	ret			;43f5
color_del_sitio:		; Compone el color mezclando el que ya hay en pantalla
	ld a,(0f87fh)		;43f6   ; el byte bajo del destino hace de coordenada X...
	ld c,a			;43f9
	ld a,(0f880h)		;43fa   ; ...y el alto, de Y
	ld e,a			;43fd
	xor a			;43fe
	ld b,a			;43ff
	ld d,a			;4400
	call 00111h		;4401   ; BIOS MAPXY - Places cursor at current cursor address | MAPXY deja el cursor grafico en ese punto
	call 0011dh		;4404   ; BIOS READC - Reads attribute byte of current screen pixel | READC devuelve el color del pixel que hay debajo
	ld b,a			;4407
	ld a,(0f881h)		;4408   ; el color pedido pasa a ser la tinta...
	sla a		;440b
	sla a		;440d
	sla a		;440f
	sla a		;4411
	add a,b			;4413   ; ...y el de la pantalla, el fondo
	ld (0f881h),a		;4414
	ret			;4417
dibuja_rectangulo:		; Vuelca un dibujo de N baldosas de ancho por M de alto
	ld a,(0f883h)		;4418   ; el byte bajo de 0xF883 es el ancho en baldosas...
	sla a		;441b   ; ...que por ocho da los bytes de cada fila
	sla a		;441d
	sla a		;441f
	ld (0f883h),a		;4421
	call color_del_sitio		;4424   ; el color, del sitio donde va a caer
L_4427:
	call bytes_por_fila		;4427   ; --- una fila de baldosas por vuelta ---
	ld de,(0f87fh)		;442a   ; destino en la tabla de patrones
	ld hl,(0f885h)		;442e   ; origen en RAM
	call 0005ch		;4431   ; BIOS LDIRVM - Block transfers to VRAM from memory
	call bytes_por_fila		;4434   ; y el mismo tramo en la tabla de colores, de un solo color
	ld hl,(0f87fh)		;4437
	ld de,02000h		;443a
	add hl,de			;443d
	ld a,(0f881h)		;443e
	call 00056h		;4441   ; BIOS FILVRM - Fills VRAM with value
	call baja_una_fila		;4444   ; el destino sube 0x100: una fila entera de baldosas
	call bytes_por_fila		;4447
	ld hl,(0f885h)		;444a   ; el origen avanza los bytes de una fila
	add hl,bc			;444d
	ld (0f885h),hl		;444e
	ld a,(0f884h)		;4451   ; el byte alto de 0xF883, o sea 0xF884, es el numero de filas
	dec a			;4454
	ld (0f884h),a		;4455
	cp 000h		;4458
	jp nz,L_4427		;445a
	ret			;445d
bytes_por_fila:		; BC = los bytes que ocupa una fila del dibujo
	ld a,(0f883h)		;445e
	ld c,a			;4461
	xor a			;4462
	ld b,a			;4463
	ret			;4464
baja_una_fila:		; Suma 0x100 al destino en VRAM: 32 baldosas
	ld a,(0f880h)		;4465
	inc a			;4468
	ld (0f880h),a		;4469
	ret			;446c
vuelca_con_color:		; Patrones y colores completos: consume 2*BC bytes
	call vuelca_patrones		;446d   ; primero los patrones, y HL queda detras de ellos
	ld (0f881h),hl		;4470
	ld hl,(0f887h)		;4473   ; el origen sigue donde acabaron los patrones
	ld (0f87fh),hl		;4476
	ld hl,(0f889h)		;4479   ; y el destino, en la tabla de colores
	ld (0f883h),hl		;447c
	jp tres_tercios		;447f   ; y se repite la copia en los tres tercios
pinta_baldosa:		; Rellena de un color las ocho filas de una baldosa, en los tres tercios
	call L_448E		;4482   ; el primer tercio...
	call baja_un_tercio		;4485   ; ...el segundo...
	call L_448E		;4488   ; ...y por caida, el tercero
	call baja_un_tercio		;448b
L_448E:
	ld a,(0f87fh)		;448e   ; ocho bytes iguales: el color de las ocho filas
	ld bc,00008h		;4491
	jp 00056h		;4494   ; BIOS FILVRM - Fills VRAM with value
vuelca_patrones:		; Copia BC bytes a la VRAM y repite en los otros dos tercios
	ld (0f887h),hl		;4497   ; 0xF887 guarda el origen para quien venga detras...
	ld (0f889h),bc		;449a   ; ...0xF889 la longitud...
	ld (0f88bh),de		;449e   ; ...y 0xF88B el destino
	ld (0f881h),de		;44a2
	ld hl,(0f887h)		;44a6
	ld (0f87fh),hl		;44a9
	ld hl,(0f889h)		;44ac
	ld (0f883h),hl		;44af
	call tres_tercios		;44b2   ; la copia, en los tres tercios
	ld hl,(0f887h)		;44b5   ; al salir, el origen ya apunta detras de lo copiado
	ld de,(0f889h)		;44b8
	add hl,de			;44bc
	ld (0f887h),hl		;44bd
	ld hl,(0f88bh)		;44c0   ; y el destino, a la tabla de colores del mismo sitio
	ld de,02000h		;44c3
	add hl,de			;44c6
	ld (0f88bh),hl		;44c7
	ret			;44ca
vuelca_comprimido:		; Como la anterior, pero un byte de color POR BALDOSA
	ld de,002d8h		;44cb   ; destino por omision: 0x2D8, la baldosa 0x5B
vuelca_comprimido_en:		; Igual, pero con el destino en DE
	call vuelca_patrones		;44ce
L_44D1:
	ld hl,(0f887h)		;44d1   ; --- un byte de color por baldosa ---
	ld a,(hl)			;44d4   ; el byte de color de esta baldosa
	ld (0f87fh),a		;44d5
	ld hl,(0f88bh)		;44d8   ; y la baldosa donde va
	ld (0f881h),hl		;44db
	call pinta_baldosa		;44de   ; ocho filas del mismo color, en los tres tercios
	call siguiente_color		;44e1   ; siguiente byte de color
	call siguiente_baldosa_color		;44e4   ; siguiente baldosa
	call quedan_ocho_menos		;44e7   ; quedan ocho bytes de patron menos
	ld de,00000h		;44ea   ; cuando la cuenta llega a cero, se acabo
	rst 20h			;44ed
	jp nz,L_44D1		;44ee
	ret			;44f1
tres_tercios:		; La misma copia en DE, DE+0x800 y DE+0x1000
	call copia_vram		;44f2   ; primer tercio
	call baja_un_tercio		;44f5
	call copia_vram		;44f8   ; segundo
	call baja_un_tercio		;44fb
copia_vram:		; LDIRVM con los tres punteros que hay en 0xF87F, 0xF881 y 0xF883
	ld hl,(0f87fh)		;44fe   ; tercero, por caida
	ld de,(0f881h)		;4501
	ld bc,(0f883h)		;4505
	jp 0005ch		;4509   ; BIOS LDIRVM - Block transfers to VRAM from memory
baja_un_tercio:		; Suma 0x800 al destino en VRAM
	ld hl,(0f881h)		;450c
	ld a,h			;450f   ; basta con sumar 8 al byte alto
	add a,008h		;4510
	ld h,a			;4512
	ld (0f881h),hl		;4513   ; y de vuelta al puntero
	ret			;4516
siguiente_color:		; Adelanta un byte el puntero de colores
	ld hl,(0f887h)		;4517   ; un byte de color por baldosa
	inc hl			;451a
	ld (0f887h),hl		;451b
	ret			;451e
siguiente_baldosa_color:		; Suma 8 al destino: la baldosa de al lado
	ld hl,(0f88bh)		;451f
	ld de,00008h		;4522   ; ocho filas por baldosa
	add hl,de			;4525
	ld (0f88bh),hl		;4526
	ret			;4529
quedan_ocho_menos:		; Descuenta ocho bytes de patron de lo que falta
	ld hl,(0f889h)		;452a
	ld de,00008h		;452d   ; una baldosa son ocho bytes de patron
	xor a			;4530
	sbc hl,de		;4531   ; el XOR de delante deja el acarreo a cero para el SBC
	ld (0f889h),hl		;4533
	ret			;4536
anima_olas:		; Recorre las cuatro baldosas del agua y les da la vuelta
	ld a,(0f893h)		;4537   ; con el protagonista en movimiento, el agua se queda quieta
	cp 000h		;453a
	ret nz			;453c
	ld a,(0f89eh)		;453d   ; una vuelta de cada cuatro
	inc a			;4540
	ld (0f89eh),a		;4541
	cp 004h		;4544
	ret nz			;4546
	xor a			;4547
	ld (0f89eh),a		;4548
	ld a,(0f88fh)		;454b   ; 0xF88F: el fotograma del oleaje, de 0 a 3
	inc a			;454e
	ld (0f88fh),a		;454f
	cp 004h		;4552
	jp nz,L_455B		;4554
	xor a			;4557
	ld (0f88fh),a		;4558
L_455B:
	ld a,(0f88fh)		;455b
	ld (0f87fh),a		;455e
	ld hl,01a40h		;4561   ; 0x1A40: la fila 18 de la tabla de nombres
	ld (0f881h),hl		;4564
L_4567:
	ld a,(0f87fh)		;4567   ; --- una baldosa por vuelta ---
	cp 000h		;456a
	jp z,L_459E		;456c   ; fotograma 0: la ola alta
	cp 002h		;456f   ; fotograma 2: la ola baja
	jp z,L_45A8		;4571
	ld a,087h		;4574   ; y los impares, la ola intermedia
	call pon_par_de_olas		;4576
	ld a,07dh		;4579
	jp pon_ola_abajo		;457b
L_457E:
	ld a,(0f87fh)		;457e   ; el fotograma va rotando de 0 a 3
	inc a			;4581
	ld (0f87fh),a		;4582
	cp 004h		;4585
	jp nz,L_458E		;4587
	xor a			;458a
	ld (0f87fh),a		;458b
L_458E:
	ld hl,(0f881h)		;458e   ; de dos en dos baldosas
	inc hl			;4591
	inc hl			;4592
	ld (0f881h),hl		;4593
	ld de,01a60h		;4596   ; 0x1A60: el final de la franja de agua
	rst 20h			;4599
	jp nz,L_4567		;459a
	ret			;459d
L_459E:
	ld a,094h		;459e
	call pon_par_de_olas		;45a0
	ld a,07dh		;45a3
	jp pon_ola_abajo		;45a5
L_45A8:
	ld a,087h		;45a8
	call pon_par_de_olas		;45aa
	ld a,089h		;45ad
	jp pon_ola_abajo		;45af
pon_par_de_olas:		; Escribe una pareja de baldosas de ola
	ld (0f880h),a		;45b2
pon_ola:		; Escribe la baldosa A y la de al lado
	ld hl,(0f881h)		;45b5
	call 0004dh		;45b8   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	ld a,(0f880h)		;45bb
	cp 07dh		;45be   ; 0x7D es la baldosa "sin ola": no gasta fotograma
	jp z,L_45C6		;45c0
	call baja_una_fila		;45c3
L_45C6:
	ld a,(0f880h)		;45c6
	ld hl,(0f881h)		;45c9
	inc hl			;45cc
	jp 0004dh		;45cd   ; BIOS WRTVRM - Writes data in VRAM
pon_ola_abajo:		; La misma pareja, una fila mas abajo
	ld (0f880h),a		;45d0   ; la baldosa que toca en la fila de abajo
	ld hl,(0f881h)		;45d3
	ld de,00020h		;45d6   ; 0x20: una fila de la tabla de nombres
	add hl,de			;45d9
	ld (0f881h),hl		;45da
	call pon_ola		;45dd   ; se escribe la pareja
	ld hl,(0f881h)		;45e0
	ld de,00020h		;45e3   ; y el puntero vuelve a la fila de arriba
	xor a			;45e6
	sbc hl,de		;45e7
	ld (0f881h),hl		;45e9
	jp L_457E		;45ec
espera_2000:		; Cuenta hasta 2000 en 0xF891: la pausa larga
	ld hl,(0f891h)		;45ef   ; 0xF891 es el contador de espera
	inc hl			;45f2
	ld (0f891h),hl		;45f3
	ld de,007d0h		;45f6   ; 0x7D0 = 2000 vueltas
	rst 20h			;45f9
	jp nz,espera_2000		;45fa
	ld hl,00000h		;45fd   ; y al llegar se pone a cero para la proxima
	ld (0f891h),hl		;4600
	ret			;4603

; ----------------------------------------------------------------------
; --- las ocho pantallas ----------------------------------
; Cada una carga sus patrones y su tabla de nombres. Los
; tamanos no se pasan como longitud del bloque de datos sino
; como longitud EN VRAM: quien sabe cuantos bytes de cinta
; consume cada bloque es la rutina de volcado, y por eso los
; bloques encajan uno detras de otro sin dejar huecos.
; ----------------------------------------------------------------------
carga_pantalla:		; Vuelca los patrones, los colores y el mapa de la pantalla 0xF893
	ld a,(0f893h)		;4604   ; ocho pantallas, de la 0 a la 7
	cp 000h		;4607
	jp z,pantalla_0		;4609   ; pantalla 0
	cp 001h		;460c
	jp z,pantalla_1		;460e   ; pantalla 1
	cp 002h		;4611
	jp z,pantalla_2		;4613
	cp 003h		;4616   ; pantalla 3
	jp z,pantalla_3		;4618
	cp 004h		;461b   ; pantalla 4
	jp z,pantalla_4		;461d
	cp 005h		;4620
	jp z,pantalla_5		;4622
	cp 006h		;4625   ; pantalla 6
	jp z,pantalla_6		;4627
	cp 007h		;462a   ; pantalla 7
	jp z,pantalla_7		;462c
	ret			;462f
pantalla_0:		; El puerto de Palos: la taberna, el muelle y el agua
	ld hl,082f5h		;4630   ; su tabla de nombres
	call vuelca_nombres		;4633
	ld hl,0aed4h		;4636   ; patrones propios: 0x1C0 bytes y 0x38 de color, a la baldosa 0x5B
	ld bc,001c0h		;4639
	call vuelca_comprimido		;463c
	ld hl,0b0cch		;463f   ; y 0x20 bytes mas con su tabla de color entera
	ld bc,00020h		;4642
	ld de,00498h		;4645
	call vuelca_con_color		;4648
	jp pinta_franja_inferior		;464b   ; al salir, redibuja la franja del agua
pantalla_1:		; Sus patrones y su tabla de nombres
	ld hl,085f5h		;464e   ; la tabla de nombres, en 0x85F5
	call vuelca_nombres		;4651
	ld hl,0b10ch		;4654   ; 0x178 bytes de patrones a la baldosa 0x5B
	ld bc,00178h		;4657
	call vuelca_comprimido		;465a
	ld hl,0b2b3h		;465d   ; y 0x40 mas a la baldosa 0x8A, con su color completo
	ld bc,00040h		;4660
	ld de,00450h		;4663
	jp vuelca_con_color		;4666
pantalla_2:		; Sus patrones y su tabla de nombres
	ld hl,088f5h		;4669   ; la tabla de nombres, en 0x88F5
	call vuelca_nombres		;466c
	ld hl,0b333h		;466f   ; 0x140 bytes de patrones a la baldosa 0x5B
	ld bc,00140h		;4672
	call vuelca_comprimido		;4675
	ld hl,0b49bh		;4678   ; y 0x70 mas a la baldosa 0x83
	ld bc,00070h		;467b
	ld de,00418h		;467e
	jp vuelca_con_color		;4681
pantalla_3:		; Sus patrones y su tabla de nombres
	ld hl,08bf5h		;4684   ; la tabla de nombres, en 0x8BF5
	call vuelca_nombres		;4687
	ld hl,0b57bh		;468a   ; 0x1A0 bytes de patrones a la baldosa 0x5B
	ld bc,001a0h		;468d
	call vuelca_comprimido		;4690
	ld hl,0b74fh		;4693   ; y 0x68 mas a la baldosa 0x8F
	ld bc,00068h		;4696
	ld de,00478h		;4699
	jp vuelca_con_color		;469c
pantalla_4:		; Sus patrones y su tabla de nombres
	ld hl,08ef5h		;469f   ; la tabla de nombres, en 0x8EF5
	call vuelca_nombres		;46a2
	ld hl,0b81fh		;46a5   ; 0x1A8 bytes de patrones a la baldosa 0x5B
	ld bc,001a8h		;46a8
	call vuelca_comprimido		;46ab
	ld hl,0b9fch		;46ae   ; y 0xA0 mas a la baldosa 0x90
	ld bc,000a0h		;46b1
	ld de,00480h		;46b4
	jp vuelca_con_color		;46b7
pantalla_5:		; El interior de la taberna; no lleva bloque de color aparte
	ld hl,091f5h		;46ba   ; la tabla de nombres, en 0x91F5
	call vuelca_nombres		;46bd
	ld hl,0bb3ch		;46c0   ; 0xF8 bytes de patrones a la baldosa 0x5B, y nada mas
	ld bc,000f8h		;46c3
	jp vuelca_comprimido		;46c6
pantalla_6:		; Sus patrones y su tabla de nombres
	ld hl,094f5h		;46c9   ; la tabla de nombres, en 0x94F5
	call vuelca_nombres		;46cc
	ld hl,0bc53h		;46cf   ; 0xA0 bytes de patrones a la baldosa 0x5B
	ld bc,000a0h		;46d2
	call vuelca_comprimido		;46d5
	ld hl,0bd07h		;46d8   ; y 0x58 mas a la baldosa 0x6F
	ld bc,00058h		;46db
	ld de,00378h		;46de
	jp vuelca_con_color		;46e1
pantalla_7:		; La del mapa ancho: la tabla de nombres se compone a mano
	call monta_mapa_ancho		;46e4   ; aqui no hay tabla que copiar: se recorta del mapa de 64 columnas
	ld hl,0bdb7h		;46e7   ; 0x198 bytes de patrones a la baldosa 0x5B
	ld bc,00198h		;46ea
	call vuelca_comprimido		;46ed
	ld hl,0bf82h		;46f0   ; y 0x48 mas a la baldosa 0x8E
	ld bc,00048h		;46f3
	ld de,00470h		;46f6
	jp vuelca_con_color		;46f9
carga_comunes:		; Los patrones que llevan todas las pantallas
	ld hl,0ab60h		;46fc   ; 0x2A0 bytes de patrones a partir de la baldosa 0
	ld bc,002a0h		;46ff
	ld de,00000h		;4702
	call vuelca_patrones		;4705   ; se prepara la copia...
	call L_44D1		;4708   ; ...y se pintan los colores, uno por baldosa
	ld hl,0ae54h		;470b   ; y 0x40 bytes mas a la baldosa 0x53, con su color completo
	ld bc,00040h		;470e
	ld de,00298h		;4711
	jp vuelca_con_color		;4714
vuelca_nombres:		; Copia una tabla de nombres de 0x300 bytes a la VRAM
	ld (0f87fh),hl		;4717
	ld hl,01800h		;471a   ; 0x1800: la tabla de nombres
	ld (0f881h),hl		;471d
	ld hl,00300h		;4720   ; 0x300 bytes: 32 por 24
	ld (0f883h),hl		;4723
	jp copia_vram		;4726
monta_mapa_ancho:		; Compone la pantalla 7 recortando 32 columnas del mapa de 64
	xor a			;4729   ; 0xF88C cuenta las filas
	ld (0f88ch),a		;472a
	ld d,a			;472d
	ld a,(0f89dh)		;472e   ; 0xF89D es la columna por la que se recorta: el scroll de la fase 7
	ld e,a			;4731
	ld hl,097f5h		;4732   ; el mapa ancho empieza en 0x97F5
	add hl,de			;4735
	ld (0f87fh),hl		;4736
	ld hl,00020h		;4739   ; 32 baldosas por fila
	ld (0f883h),hl		;473c
	ld hl,01800h		;473f   ; y van a la tabla de nombres
	ld (0f881h),hl		;4742
L_4745:
	call copia_vram		;4745   ; --- una fila por vuelta ---
	ld hl,(0f87fh)		;4748
	ld de,00040h		;474b   ; el mapa tiene 64 baldosas de ancho, por eso el paso es 0x40...
	add hl,de			;474e
	ld (0f87fh),hl		;474f
	ld hl,(0f881h)		;4752
	ld de,00020h		;4755   ; ...mientras que en la pantalla solo caben 32
	add hl,de			;4758
	ld (0f881h),hl		;4759
	ld a,(0f88ch)		;475c
	inc a			;475f
	ld (0f88ch),a		;4760
	cp 018h		;4763   ; veinticuatro filas
	jr nz,L_4745		;4765
	ret			;4767
mueve_al_protagonista:		; Anima y desplaza al personaje segun el mando
	ld a,(0f89ch)		;4768   ; con 0xF89C a 0xFF el protagonista esta fuera de juego
	cp 0ffh		;476b
	ret z			;476d
	call apunta_al_protagonista		;476e   ; recalcula los punteros de la ficha y de los sprites
	call lee_mando		;4771   ; lee el mando
	cp 001h		;4774
	jp z,L_47A0		;4776
	ld a,(0f894h)		;4779   ; 3 = a la derecha
	cp 003h		;477c
	jp z,L_47D8		;477e
	ld a,(0f894h)		;4781   ; 5 = abajo
	cp 005h		;4784
	jp z,L_47F1		;4786
	ld a,(0f894h)		;4789   ; 7 = a la izquierda
	cp 007h		;478c
	jp z,L_480A		;478e
	ld a,004h		;4791   ; sin direccion, el fotograma se queda como esta
	call campo_del_objeto		;4793
	cp 000h		;4796
	jp z,pinta_al_protagonista		;4798
	xor a			;479b
	ld (hl),a			;479c
	jp pinta_al_protagonista		;479d
L_47A0:
	ld a,003h		;47a0   ; --- arriba ---
	call campo_del_objeto		;47a2
	cp 001h		;47a5
	jp nz,L_47B0		;47a7
	call anda_hacia_arriba		;47aa   ; sube una fila si la baldosa de encima lo permite
	jp L_4823		;47ad
L_47B0:
	ld a,(hl)			;47b0
	cp 000h		;47b1
	jp nz,L_47C3		;47b3
L_47B6:
	ld a,(hl)			;47b6   ; el fotograma del paso avanza de 0 a 3...
	inc a			;47b7
	ld (hl),a			;47b8
	cp 004h		;47b9
	jp nz,L_47D2		;47bb
	xor a			;47be
	ld (hl),a			;47bf
	jp L_47D2		;47c0
L_47C3:
	ld a,(hl)			;47c3   ; ...o retrocede, segun hacia donde se ande
	cp 000h		;47c4
	jp z,L_47CF		;47c6
	ld a,(hl)			;47c9
	dec a			;47ca
	ld (hl),a			;47cb
	jp L_47D2		;47cc
L_47CF:
	ld a,003h		;47cf
	ld (hl),a			;47d1
L_47D2:
	inc hl			;47d2
	xor a			;47d3
	ld (hl),a			;47d4
	jp pinta_al_protagonista		;47d5
L_47D8:
	ld a,003h		;47d8   ; --- a la derecha ---
	call campo_del_objeto		;47da
	cp 002h		;47dd
	jp nz,L_47E8		;47df
	call anda_a_la_derecha		;47e2
	jp L_4823		;47e5
L_47E8:
	ld a,(hl)			;47e8
	cp 001h		;47e9
	jp z,L_47B6		;47eb
	jp L_47C3		;47ee
L_47F1:
	ld a,003h		;47f1   ; --- abajo ---
	call campo_del_objeto		;47f3
	cp 003h		;47f6
	jp nz,L_4801		;47f8
	call anda_hacia_abajo		;47fb
	jp L_4823		;47fe
L_4801:
	ld a,(hl)			;4801
	cp 000h		;4802
	jp z,L_47C3		;4804
	jp L_47B6		;4807
L_480A:
	ld a,003h		;480a   ; --- a la izquierda ---
	call campo_del_objeto		;480c
	cp 000h		;480f
	jp nz,L_481A		;4811
	call anda_a_la_izquierda		;4814
	jp L_4823		;4817
L_481A:
	ld a,(hl)			;481a
	cp 001h		;481b
	jp z,L_47C3		;481d
	jp L_47B6		;4820
L_4823:
	ld a,004h		;4823   ; al andar de verdad, un fotograma mas
	call campo_del_objeto		;4825
	inc a			;4828
	ld (hl),a			;4829
	cp 004h		;482a
	jp nz,pinta_al_protagonista		;482c
	xor a			;482f
	ld (hl),a			;4830
pinta_al_protagonista:		; Deja al muñeco en su sitio, con su sprite y su color
	ld a,003h		;4831   ; estado 2: el muñeco esta cayendo o subiendo
	call campo_del_objeto		;4833
	cp 002h		;4836
	jp z,pinta_cayendo		;4838
	ld a,(hl)			;483b   ; con el estado a cero no hay nada que dibujar
	cp 000h		;483c
	jp z,pinta_quieto		;483e
	ld a,(0d6d8h)		;4841   ; 0xD6D8 sobrevive entre las dos partes del juego
	cp 000h		;4844
	call nz,alterna_d6d8		;4846
coloca_la_figura:		; Deja el sprite base donde toca segun el estado
	ld a,003h		;4849
	call campo_del_objeto		;484b
	cp 003h		;484e   ; estado 3: la figura no se mueve de sitio
	jp z,L_4869		;4850
	ld a,(hl)			;4853   ; estado 1: la variante de 0x4958
	cp 001h		;4854
	jp z,L_4958		;4856
	ld hl,(0f87fh)		;4859   ; se guarda la posicion antes de tocarla
	ld (0f889h),hl		;485c
	ld de,000f0h		;485f   ; 0xF0: el desplazamiento hasta el sprite de esta postura
L_4862:
	ld hl,(0f87fh)		;4862
	add hl,de			;4865
	ld (0f87fh),hl		;4866
L_4869:
	ld hl,00078h		;4869   ; 0x78: la altura de la figura
	ld (0f883h),hl		;486c
	call copia_vram		;486f   ; sube el sprite a la VRAM
	call pon_sprite		;4872   ; y elige el patron que toca
	call pon_sprite_de_brazo		;4875
	ld hl,(0f881h)		;4878
	ld de,03800h		;487b   ; 0x3800 es la tabla de patrones de sprite
	xor a			;487e
	sbc hl,de		;487f
	ld (0f884h),a		;4881
	ld bc,00008h		;4884   ; ocho bytes por pieza de sprite
	ld de,00000h		;4887
L_488A:
	rst 20h			;488a   ; --- de ocho en ocho bytes se saca el numero de patron ---
	jp z,L_489B		;488b
	xor a			;488e
	sbc hl,bc		;488f
	ld a,(0f884h)		;4891
	inc a			;4894
	ld (0f884h),a		;4895
	jp nz,L_488A		;4898
L_489B:
	ld hl,01b28h		;489b   ; 0x1B28: la decima entrada de la tabla de atributos de sprite
	ld (0f885h),hl		;489e
	ld a,(0f884h)		;48a1   ; el numero de patron calculado
	ld (0f881h),a		;48a4
	ld hl,(0f887h)		;48a7   ; X e Y del muñeco, de su propia ficha
	ld a,(hl)			;48aa
	ld (0f880h),a		;48ab
	inc hl			;48ae
	ld a,(hl)			;48af
	ld (0f87fh),a		;48b0
	call patron_base		;48b3   ; y a partir de aqui, las dieciseis piezas de la figura
	call fila_de_cuatro		;48b6
	call ocho_a_la_derecha		;48b9
	call patron_mas_0		;48bc
	call fila_de_cuatro		;48bf
	call ocho_a_la_izquierda		;48c2
	call dieciseis_abajo		;48c5
	call patron_mas_10		;48c8
	call fila_de_dos		;48cb
	call ocho_a_la_derecha		;48ce
	call patron_mas_8		;48d1
	call fila_de_dos		;48d4
	call ocho_a_la_izquierda		;48d7
	call dieciseis_arriba		;48da
	call patron_mas_12		;48dd
	call remate_de_figura		;48e0
	call dieciseis_abajo		;48e3
	call dieciseis_abajo		;48e6
	call patron_mas_16		;48e9
	call pieza_suelta		;48ec
	call ocho_a_la_derecha		;48ef
	call patron_mas_15		;48f2
	call pieza_suelta		;48f5
	call ocho_a_la_izquierda		;48f8
	call patron_mas_18		;48fb
	call ultima_pieza		;48fe
	call ocho_a_la_derecha		;4901
	call patron_mas_17		;4904
	jp ultima_pieza		;4907
ocho_a_la_derecha:		; X += 8: la pieza de sprite de al lado
	ld a,(0f880h)		;490a
	add a,008h		;490d
	ld (0f880h),a		;490f
	ret			;4912
ocho_a_la_izquierda:		; X -= 8
	ld a,(0f880h)		;4913
	sub 008h		;4916
	ld (0f880h),a		;4918
	ret			;491b
dieciseis_abajo:		; Y += 0x10
	ld a,(0f87fh)		;491c
	add a,010h		;491f
	ld (0f87fh),a		;4921
	ret			;4924
dieciseis_arriba:		; Y -= 0x10
	ld a,(0f87fh)		;4925
	sub 010h		;4928
	ld (0f87fh),a		;492a
	ret			;492d
pinta_cayendo:		; Variante del dibujo cuando el estado vale 2
	ld a,005h		;492e   ; el campo 5 de la ficha es el parpadeo
	call campo_del_objeto		;4930
	cp 000h		;4933
	call nz,parpadea		;4935   ; con parpadeo, se alterna la figura
	ld a,(0d6d8h)		;4938   ; y 0xD6D8 va y viene entre las dos posturas
	cp 000h		;493b
	call nz,alterna_d6d8		;493d
	jp coloca_la_figura		;4940
pinta_quieto:		; Variante del dibujo cuando el estado vale 0
	ld a,005h		;4943   ; el campo 5 de la ficha
	call campo_del_objeto		;4945
	cp 000h		;4948
	call z,parpadea		;494a   ; sin parpadeo, se alterna igual pero al reves
	ld a,(0d6d8h)		;494d
	cp 000h		;4950
	call z,alterna_d6d8		;4952
	jp coloca_la_figura		;4955
L_4958:
	ld de,00078h		;4958
	jp L_4862		;495b
fila_de_cuatro:		; Cuatro piezas de sprite en fila y vuelta al principio
	ld a,006h		;495e   ; patron base + 6
	call campo_del_objeto		;4960
	call pon_pieza		;4963
	ld a,007h		;4966   ; patron base + 7, tres veces seguidas
	call campo_del_objeto		;4968
	call pon_pieza		;496b
	call pon_pieza		;496e
	call pon_pieza		;4971
	ld a,(0f87fh)		;4974   ; y la X vuelve 0x20 pixeles atras: cuatro piezas
	sub 020h		;4977
L_4979:
	ld (0f87fh),a		;4979
	ret			;497c
fila_de_dos:		; Dos piezas de sprite en fila
	ld a,008h		;497d   ; patron base + 8
	call campo_del_objeto		;497f
	call pon_pieza		;4982
	call pon_pieza		;4985
	ld a,(0f87fh)		;4988   ; y la X vuelve 0x10 atras
	sub 010h		;498b
	jp L_4979		;498d
remate_de_figura:		; Las piezas sueltas de arriba: la cabeza y los brazos
	ld a,(0f87fh)		;4990   ; cinco pixeles a la derecha...
	add a,005h		;4993
	ld (0f87fh),a		;4995
	ld a,(0f880h)		;4998   ; ...y cuatro hacia abajo
	add a,004h		;499b
	ld (0f880h),a		;499d
	ld a,009h		;49a0   ; patron base + 9
	call campo_del_objeto		;49a2
	call pon_pieza		;49a5
	ld a,(0f87fh)		;49a8   ; ocho pixeles atras
	sub 008h		;49ab
	ld (0f87fh),a		;49ad
	ld a,00ah		;49b0   ; patron base + 10
	call campo_del_objeto		;49b2
	call pon_pieza		;49b5
	ld a,(0f87fh)		;49b8   ; un pixel atras
	dec a			;49bb
	ld (0f87fh),a		;49bc
	ld a,00bh		;49bf   ; patron base + 11
	call campo_del_objeto		;49c1
	call pon_pieza		;49c4
	ld a,001h		;49c7   ; y el color, del campo 1 de la ficha
	call campo_del_objeto		;49c9
	ld (0f880h),a		;49cc
	inc hl			;49cf
	ld a,(hl)			;49d0
	jp L_4979		;49d1
pieza_suelta:		; Una pieza de sprite y ocho pixeles atras
	ld a,007h		;49d4   ; patron base + 7
	call campo_del_objeto		;49d6
	call pon_pieza		;49d9
	ld a,(0f87fh)		;49dc   ; ocho pixeles a la izquierda
	sub 008h		;49df
	jp L_4979		;49e1
ultima_pieza:		; La ultima pieza de la figura
	ld a,001h		;49e4
	call pon_pieza		;49e6
	ld a,(0f87fh)		;49e9
	sub 008h		;49ec
	jp L_4979		;49ee
pon_pieza:		; Escribe una entrada de la tabla de atributos: Y, X, patron y color
	ld (0f882h),a		;49f1   ; 0xF882 es el numero de patron
	ld a,(0f8c2h)		;49f4   ; 0xF8C2 marca la caida: entonces la figura se recorta por abajo
	cp 000h		;49f7
	jp nz,L_4A35		;49f9
	ld a,(0f87fh)		;49fc
L_49FF:
	call escribe_atributo		;49ff   ; Y
	ld a,(0f880h)		;4a02   ; X
	call escribe_atributo		;4a05   ; numero de patron
	ld a,(0f881h)		;4a08   ; color
	call escribe_atributo		;4a0b
	ld a,(0f882h)		;4a0e
	call escribe_atributo		;4a11
	ld a,(0f881h)		;4a14   ; el siguiente sprite lleva el patron siguiente
	inc a			;4a17
	ld (0f881h),a		;4a18
	ld a,(0f87fh)		;4a1b   ; y va ocho pixeles mas abajo
	add a,008h		;4a1e
	ld (0f87fh),a		;4a20
	ld a,(0f882h)		;4a23
	ret			;4a26
escribe_atributo:		; Un byte a la tabla de atributos y adelante el puntero
	ld hl,(0f885h)		;4a27
	call 0004dh		;4a2a   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	ld hl,(0f885h)		;4a2d   ; y a la casilla siguiente
	inc hl			;4a30
	ld (0f885h),hl		;4a31
	ret			;4a34
L_4A35:
	ld a,(0f87fh)		;4a35   ; cayendo, todo lo que pase de la fila 0xA0 se manda fuera
	cp 0a0h		;4a38
	jp c,L_49FF		;4a3a
	ld a,0d1h		;4a3d   ; 0xD1: fuera de la pantalla por abajo
	jp L_49FF		;4a3f
patron_base:		; Deja en 0xF881 el patron de partida de la figura
	ld a,004h		;4a42   ; desplazamiento 4 respecto del patron de la postura
L_4A44:
	ld (0f889h),a		;4a44   ; se guarda el desplazamiento pedido
	ld a,003h		;4a47
	call campo_del_objeto		;4a49   ; el campo 3 de la ficha es el estado
	cp 000h		;4a4c
	ret nz			;4a4e   ; con estado distinto de cero no se toca el patron
	ld a,(0f889h)		;4a4f
	ld e,a			;4a52
	ld a,(0f884h)		;4a53   ; 0xF884 trae el patron de la postura
	add a,e			;4a56
	ld (0f881h),a		;4a57   ; y la suma es el patron con el que se empieza a dibujar
	ret			;4a5a
patron_mas_0:		; La figura sin desplazamiento
	xor a			;4a5b
	jp L_4A44		;4a5c
patron_mas_10:		; Diez patrones mas alla
	ld a,00ah		;4a5f
	jp L_4A44		;4a61
patron_mas_8:		; Ocho patrones mas alla
	ld a,008h		;4a64
	jp L_4A44		;4a66
patron_mas_16:		; Dieciseis patrones mas alla
	ld a,010h		;4a69
	jp L_4A44		;4a6b
patron_mas_15:		; Quince patrones mas alla
	ld a,00fh		;4a6e
	jp L_4A44		;4a70
patron_mas_18:		; Dieciocho patrones mas alla
	ld a,012h		;4a73
	jp L_4A44		;4a75
patron_mas_17:		; Diecisiete patrones mas alla
	ld a,011h		;4a78
	jp L_4A44		;4a7a
patron_mas_12:		; Doce patrones mas alla
	ld a,00ch		;4a7d
	jp L_4A44		;4a7f
pon_sprite:		; Elige el patron de sprite que toca y lo sube a la VRAM
	ld hl,(0f881h)		;4a82   ; 0x78 por debajo del patron base
	ld de,00078h		;4a85
	add hl,de			;4a88
	ex de,hl			;4a89
	ld bc,00010h		;4a8a   ; dieciseis bytes: media figura de 16x16
	ld hl,09e05h		;4a8d   ; el sprite de partida
	call 0005ch		;4a90   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld a,003h		;4a93   ; estado 1: el muñeco esta parado
	call campo_del_objeto		;4a95
	cp 001h		;4a98
	jp z,L_4AD3		;4a9a
	ld a,(hl)			;4a9d
	cp 003h		;4a9e
	jp z,L_4AD3		;4aa0
	ld a,004h		;4aa3   ; el campo 4 de la ficha es el fotograma del paso
	call campo_del_objeto		;4aa5
	inc a			;4aa8
	ld (0f883h),a		;4aa9
	ld hl,09e05h		;4aac   ; los fotogramas van de dieciseis en dieciseis bytes
	ld de,00010h		;4aaf
L_4AB2:
	add hl,de			;4ab2   ; --- salta tantos fotogramas como diga el campo 4 ---
	ld a,(0f883h)		;4ab3
	dec a			;4ab6
	ld (0f883h),a		;4ab7
	cp 000h		;4aba
	jp nz,L_4AB2		;4abc
L_4ABF:
	ld (0f885h),hl		;4abf   ; y la otra media figura, 0x10 mas alla
	ld hl,(0f881h)		;4ac2
	ld de,00088h		;4ac5   ; 0x88 por debajo del patron base
	add hl,de			;4ac8
	ex de,hl			;4ac9
	ld hl,(0f885h)		;4aca
	ld bc,00010h		;4acd
	jp 0005ch		;4ad0   ; BIOS LDIRVM - Block transfers to VRAM from memory
L_4AD3:
	ld hl,09df5h		;4ad3   ; parado: el sprite de 0x9DF5
	jp L_4ABF		;4ad6
parpadea:		; Alterna el fotograma de parpadeo y voltea la figura
	ld a,005h		;4ad9
	call campo_del_objeto		;4adb
	ld a,(hl)			;4ade
	inc a			;4adf   ; el campo 5 de la ficha alterna entre 0 y 1
	ld (hl),a			;4ae0
	cp 002h		;4ae1
	jp nz,L_4AE8		;4ae3
	xor a			;4ae6
	ld (hl),a			;4ae7
L_4AE8:
	ld hl,(0f87fh)		;4ae8   ; la mitad de arriba de la figura
	ld de,000f0h		;4aeb
	add hl,de			;4aee
	ld (0f889h),hl		;4aef
	ld de,00078h		;4af2
	add hl,de			;4af5
	ex de,hl			;4af6
	ld hl,(0f889h)		;4af7
	call voltea_bits		;4afa   ; y se le da la vuelta a cada byte
	ld a,005h		;4afd
	call campo_del_objeto		;4aff
	ld e,a			;4b02
	ld a,(0d6d8h)		;4b03
	cp e			;4b06
	ret z			;4b07
alterna_d6d8:		; 0xD6D8 va y viene entre 0 y 1: el balanceo del muñeco
	ld a,(0d6d8h)		;4b08   ; el byte esta por encima de 0xD300, o sea que sobrevive a la recarga
	inc a			;4b0b
	ld (0d6d8h),a		;4b0c
	cp 001h		;4b0f   ; al llegar a 1 se queda...
	jp z,L_4B18		;4b11
	xor a			;4b14   ; ...y si pasa, vuelve a cero
	ld (0d6d8h),a		;4b15
L_4B18:
	ld hl,09e05h		;4b18   ; y con el, los sprites de 0x9E05 a 0x9E54
	ld de,09e55h		;4b1b
voltea_bits:		; Invierte el orden de los bits de cada byte entre HL y DE
	xor a			;4b1e   ; asi se consigue el dibujo mirando al otro lado sin gastar mas bytes
	ld b,a			;4b1f
	ld a,(hl)			;4b20   ; el byte original
	bit 0,a		;4b21   ; bit 0 del original...
	call nz,bit0_a_bit7		;4b23   ; ...pasa a ser el bit 7 del resultado
	bit 1,a		;4b26
	call nz,L_4B53		;4b28
	bit 2,a		;4b2b
	call nz,L_4B56		;4b2d
	bit 3,a		;4b30
	call nz,L_4B59		;4b32
	bit 4,a		;4b35
	call nz,L_4B5C		;4b37
	bit 5,a		;4b3a
	call nz,L_4B5F		;4b3c
	bit 6,a		;4b3f
	call nz,L_4B62		;4b41
	bit 7,a		;4b44
	call nz,L_4B65		;4b46
	ld (hl),b			;4b49   ; y el byte volteado se escribe encima del original
	inc hl			;4b4a
	rst 20h			;4b4b   ; hasta llegar a DE
	jp nz,voltea_bits		;4b4c
	ret			;4b4f
bit0_a_bit7:		; Uno de los ocho pasos del volteo
	set 7,b		;4b50
	ret			;4b52
L_4B53:
	set 6,b		;4b53
	ret			;4b55
L_4B56:
	set 5,b		;4b56
	ret			;4b58
L_4B59:
	set 4,b		;4b59
	ret			;4b5b
L_4B5C:
	set 3,b		;4b5c
	ret			;4b5e
L_4B5F:
	set 2,b		;4b5f
	ret			;4b61
L_4B62:
	set 1,b		;4b62
	ret			;4b64
L_4B65:
	set 0,b		;4b65
	ret			;4b67
baja_cuatro:		; (HL) += 4: cuatro pixeles hacia abajo o hacia la derecha
	ld a,(hl)			;4b68
	add a,004h		;4b69
	ld (hl),a			;4b6b
	ret			;4b6c
sube_cuatro:		; (HL) -= 4
	ld a,(hl)			;4b6d
	sub 004h		;4b6e
	ld (hl),a			;4b70
	ret			;4b71
anda_a_la_izquierda:		; Cuatro pixeles a la izquierda, si la baldosa deja
	ld a,001h		;4b72   ; el campo 1 de la ficha es la X
	call campo_del_objeto		;4b74
	cp 000h		;4b77   ; en la columna 0 no se puede ir mas a la izquierda
	ret z			;4b79
	call sube_cuatro		;4b7a   ; se prueba a mover...
	call puede_pasar		;4b7d   ; ...y si la baldosa no deja, se deshace
	cp 001h		;4b80
	jp z,scroll_a_la_izquierda		;4b82
deshaz_izquierda:		; Devuelve al muñeco los cuatro pixeles
	ld a,001h		;4b85
L_4B87:
	call campo_del_objeto		;4b87
	jp baja_cuatro		;4b8a
anda_a_la_derecha:		; Cuatro pixeles a la derecha, si la baldosa deja
	ld a,001h		;4b8d
	call campo_del_objeto		;4b8f
	cp 0f0h		;4b92   ; 0xF0 es el borde derecho: ahi se cambia de pantalla
	jp z,mira_las_puertas		;4b94
	call baja_cuatro		;4b97   ; se prueba a mover...
	call puede_pasar		;4b9a   ; ...y se mira que hay
	cp 001h		;4b9d
	jp z,scroll_a_la_derecha		;4b9f
deshaz_derecha:		; Devuelve al muñeco los cuatro pixeles
	ld a,001h		;4ba2
L_4BA4:
	call campo_del_objeto		;4ba4
	jp sube_cuatro		;4ba7
anda_hacia_arriba:		; Cuatro pixeles hacia arriba, si la baldosa deja
	ld a,002h		;4baa   ; el campo 2 de la ficha es la Y
	call campo_del_objeto		;4bac
	cp 000h		;4baf   ; en la fila 0 no se sube mas
	ret z			;4bb1
	call sube_cuatro		;4bb2   ; se prueba...
	call puede_pasar		;4bb5   ; ...y si no deja, se queda como estaba
	cp 001h		;4bb8
	ret z			;4bba
	ld a,002h		;4bbb
	jp L_4B87		;4bbd
anda_hacia_abajo:		; Cuatro pixeles hacia abajo, si la baldosa deja
	ld a,002h		;4bc0
	call campo_del_objeto		;4bc2
	cp 098h		;4bc5   ; 0x98 es el borde de abajo
	jp z,mira_las_puertas		;4bc7
	call baja_cuatro		;4bca   ; se prueba a bajar
	call puede_pasar		;4bcd
	cp 001h		;4bd0
	ret z			;4bd2
	ld a,(0f893h)		;4bd3   ; en la pantalla 0, salirse por abajo es caerse al agua
	cp 000h		;4bd6
	jp z,se_acabo		;4bd8
	ld a,002h		;4bdb
	jp L_4BA4		;4bdd
scroll_a_la_derecha:		; En la pantalla 7, corre el mapa ancho una columna
	ld a,(0f893h)		;4be0
	cp 007h		;4be3   ; solo la pantalla 7 tiene mapa ancho
	ret nz			;4be5
	ld a,001h		;4be6
	call campo_del_objeto		;4be8
	bit 2,a		;4beb   ; bit 2 del estado: el muñeco esta a ras de suelo
	ret z			;4bed
	ld a,(0f89dh)		;4bee
	cp 020h		;4bf1   ; 0x20 es el tope: media pantalla de recorrido
	ret z			;4bf3
	inc a			;4bf4
	ld (0f89dh),a		;4bf5
	call deshaz_derecha		;4bf8   ; el muñeco vuelve una columna atras para compensar
L_4BFB:
	call monta_mapa_ancho		;4bfb   ; y se recompone la pantalla
	jp apunta_al_protagonista		;4bfe
scroll_a_la_izquierda:		; Lo mismo hacia el otro lado
	ld a,(0f893h)		;4c01
	cp 007h		;4c04   ; solo en la pantalla 7
	ret nz			;4c06
	ld a,001h		;4c07
	call campo_del_objeto		;4c09
	bit 2,a		;4c0c   ; el muñeco tiene que ir a ras de suelo
	ret z			;4c0e
	ld a,(0f89dh)		;4c0f
	cp 000h		;4c12   ; y en la columna 0 no hay mas que correr
	ret z			;4c14
	dec a			;4c15
	ld (0f89dh),a		;4c16
	call deshaz_izquierda		;4c19   ; se compensa el movimiento y se recompone
	jp L_4BFB		;4c1c
campo_del_objeto:		; Devuelve el byte A-1 de la ficha de objeto en 0xF887
	dec a			;4c1f   ; cada ficha son once bytes; el 1 es X, el 2 es Y, el 3 el estado...
	ld e,a			;4c20
	xor a			;4c21
	ld d,a			;4c22
	ld hl,(0f887h)		;4c23   ; la ficha en curso
	add hl,de			;4c26
	ld a,(hl)			;4c27   ; y el campo pedido
	ret			;4c28
pon_sprite_de_brazo:		; El sprite del brazo, que cambia con lo que se lleva
	ld a,004h		;4c29
	call campo_del_objeto		;4c2b
	cp 000h		;4c2e   ; sin fotograma, no hay brazo que dibujar
	ret z			;4c30
	ld (0f883h),a		;4c31
	dec hl			;4c34
	ld a,(hl)			;4c35
	cp 001h		;4c36
	jp z,L_4C6E		;4c38
	ld a,(hl)			;4c3b
	cp 003h		;4c3c
	jp z,L_4C6E		;4c3e
	ld hl,09e15h		;4c41   ; los brazos empiezan en 0x9E15
	ld de,00010h		;4c44
L_4C47:
	ld a,(0f883h)		;4c47   ; --- salta tantos brazos como diga el campo 4 ---
	cp 000h		;4c4a
	jp z,L_4C5A		;4c4c
	add hl,de			;4c4f
	ld a,(0f883h)		;4c50
	dec a			;4c53
	ld (0f883h),a		;4c54
	jp L_4C47		;4c57
L_4C5A:
	ld (0f889h),hl		;4c5a   ; el brazo elegido
	ld hl,(0f881h)		;4c5d   ; 0x88 por debajo del patron base
	ld de,00088h		;4c60
	add hl,de			;4c63
	ex de,hl			;4c64
	ld hl,(0f889h)		;4c65
	ld bc,00010h		;4c68
	jp 0005ch		;4c6b   ; BIOS LDIRVM - Block transfers to VRAM from memory
L_4C6E:
	ld a,(0f883h)		;4c6e   ; estado 2: el brazo se lee de la propia pantalla
	cp 002h		;4c71
	ret z			;4c73
	ld a,(0f883h)		;4c74
	cp 001h		;4c77
	jp z,L_4CB4		;4c79
	ld de,00088h		;4c7c
L_4C7F:
	ld hl,(0f881h)		;4c7f   ; se recogen los bytes de la VRAM uno a uno...
	add hl,de			;4c82
	ld (0f885h),hl		;4c83
	ld a,003h		;4c86
	call campo_del_objeto		;4c88
	cp 003h		;4c8b
	jp z,L_4CBA		;4c8d
	ld bc,00004h		;4c90
	ld de,00004h		;4c93
	ld a,004h		;4c96
L_4C98:
	ld (0f883h),a		;4c98
L_4C9B:
	ld hl,(0f885h)		;4c9b
	add hl,de			;4c9e
	call 0004ah		;4c9f   ; BIOS RDVRM - Reads the content of VRAM | ...con RDVRM...
	call escribe_atributo		;4ca2
	ld a,(0f883h)		;4ca5
	dec a			;4ca8
	ld (0f883h),a		;4ca9
	cp 000h		;4cac
	jp nz,L_4C9B		;4cae
	jp 00056h		;4cb1   ; BIOS FILVRM - Fills VRAM with value | ...y se sueltan como color de sprite
L_4CB4:
	ld de,00090h		;4cb4
	jp L_4C7F		;4cb7
L_4CBA:
	ld bc,00003h		;4cba
	ld de,00002h		;4cbd
	ld a,005h		;4cc0
	jp L_4C98		;4cc2

; ----------------------------------------------------------------------
; --- el bucle del juego ----------------------------------
; ----------------------------------------------------------------------
arranca_el_juego:		; Carga la pantalla 0 y entra en el bucle
	call carga_comunes		;4cc5
	call carga_pantalla		;4cc8
bucle_principal:		; Dieciseis llamadas por vuelta, hasta que 0xF8A6 avise
	call espera_2000		;4ccb   ; la pausa que marca el ritmo
	call musica_de_la_pantalla		;4cce   ; la musica de la pantalla en la que estamos
	call mueve_al_protagonista		;4cd1   ; el muñeco
	call anima_olas		;4cd4
	call cuenta_atras		;4cd7
	call mira_el_cofre		;4cda
	call pinta_el_marcador		;4cdd
	call mira_la_llave		;4ce0
	call anima_la_puerta		;4ce3
	call mira_el_barril		;4ce6
	call escena_de_la_taberna		;4ce9
	call anima_el_pajaro		;4cec
	call anima_la_bandera		;4cef
	call el_gran_salto		;4cf2
	call mira_el_permiso		;4cf5
	call escena_de_la_nave		;4cf8
	ld a,(0f8a6h)		;4cfb   ; 0xF8A6: alguien ha pedido cambiar de escena
	cp 000h		;4cfe
	jp z,bucle_principal		;4d00
bucle_de_escena:		; El bucle corto de las escenas sin control del jugador
	call espera_2000		;4d03   ; aqui el mando no pinta nada: la escena va sola
	call musica_de_la_pantalla		;4d06   ; la musica sigue
	call anima_el_pajaro		;4d09
	call anima_la_bandera		;4d0c
	call paso_de_escena		;4d0f   ; un paso de la escena
	call arranca_la_escena		;4d12
	ld a,(0f8a7h)		;4d15   ; 0xF8A7 lleva el paso de la escena; el 9 la termina
	cp 000h		;4d18
	jp z,bucle_de_escena		;4d1a
	cp 009h		;4d1d
	jp z,L_4D2B		;4d1f
	call apunta_al_protagonista		;4d22   ; mientras dura, el muñeco se sigue dibujando
	call pinta_al_protagonista		;4d25
	jp bucle_de_escena		;4d28
L_4D2B:
	xor a			;4d2b   ; y al acabar se vuelve al bucle largo
	ld (0f8a6h),a		;4d2c
	ld (0f8a7h),a		;4d2f
	jp bucle_principal		;4d32
puede_pasar:		; Mira la baldosa que hay delante y dice si se puede pisar
	ld a,(0f894h)		;4d35   ; andando en horizontal se mira solo la baldosa de delante...
	cp 003h		;4d38
	jp z,baldosa_de_delante		;4d3a
	ld a,(0f894h)		;4d3d
	cp 007h		;4d40
	jp z,baldosa_de_delante		;4d42
	call baldosa_de_delante		;4d45   ; ...pero en vertical hay que mirar tambien la de detras
	cp 000h		;4d48
	ret z			;4d4a
	ld a,001h		;4d4b   ; por eso se adelanta el muñeco, se mira, y se deshace
	call campo_del_objeto		;4d4d
	call baja_cuatro		;4d50
	call baldosa_de_delante		;4d53
	ld (0f883h),a		;4d56
	ld a,001h		;4d59
	call campo_del_objeto		;4d5b
	call sube_cuatro		;4d5e
	ld a,(0f883h)		;4d61
	ret			;4d64
baldosa_de_delante:		; Devuelve el numero de la baldosa que hay bajo el muñeco
	ld a,001h		;4d65
	call campo_del_objeto		;4d67
	ld (0f883h),a		;4d6a
	ld a,(0f894h)		;4d6d   ; andando hacia la derecha se mira cuatro pixeles mas alla
	cp 003h		;4d70
	jp nz,L_4D7D		;4d72
	ld a,(0f883h)		;4d75
	add a,004h		;4d78
	ld (0f883h),a		;4d7a
L_4D7D:
	ld a,(0f883h)		;4d7d   ; +4 y dividido entre 8: de pixeles a columna
	add a,004h		;4d80
	srl a		;4d82
	srl a		;4d84
	srl a		;4d86
	ld e,a			;4d88
	xor a			;4d89
	ld d,a			;4d8a
	ld hl,01800h		;4d8b   ; 0x1800: la tabla de nombres
	add hl,de			;4d8e
	ld (0f883h),hl		;4d8f
	ld a,002h		;4d92
	call campo_del_objeto		;4d94
	add a,024h		;4d97   ; la Y, con el mismo apaño, da la fila
	srl a		;4d99
	srl a		;4d9b
	srl a		;4d9d
	ld hl,(0f883h)		;4d9f
	ld de,00020h		;4da2
	ld (0f883h),a		;4da5
L_4DA8:
	ld a,(0f883h)		;4da8   ; y cada fila son 0x20 baldosas
	cp 000h		;4dab
	jp z,L_4DBB		;4dad
	add hl,de			;4db0
	ld a,(0f883h)		;4db1
	dec a			;4db4
	ld (0f883h),a		;4db5
	jp L_4DA8		;4db8
L_4DBB:
	call 0004ah		;4dbb   ; BIOS RDVRM - Reads the content of VRAM | RDVRM: el numero de baldosa
	ld (0f883h),a		;4dbe
	ld a,(0f893h)		;4dc1   ; y cada pantalla tiene su lista de baldosas que no se pisan
	cp 000h		;4dc4
	jp z,solidas_pantalla_0		;4dc6
	cp 001h		;4dc9
	jp z,solidas_pantalla_1		;4dcb
	cp 002h		;4dce
	jp z,solidas_pantalla_2		;4dd0
	cp 003h		;4dd3
	jp z,solidas_pantalla_3		;4dd5
	cp 004h		;4dd8
	jp z,solidas_pantalla_4		;4dda
	cp 005h		;4ddd
	jp z,solidas_pantalla_5		;4ddf
	cp 006h		;4de2
	jp z,solidas_pantalla_6		;4de4
	cp 007h		;4de7
	jp z,solidas_pantalla_7		;4de9
no_se_puede:		; Devuelve 1: hay algo delante
	ld a,001h		;4dec
	ret			;4dee

; ----------------------------------------------------------------------
; --- las baldosas por las que no se pasa -----------------
; Una lista de comparaciones por pantalla, sin tabla: cada
; `cp` es un numero de baldosa contra el que se choca. Se
; entiende mejor mirando el dibujo de la pantalla que leyendo
; la lista; tools/dibuja.py las saca todas.
; ----------------------------------------------------------------------
solidas_pantalla_0:		; Las dos baldosas por las que no se pasa en el puerto
	ld a,(0f883h)		;4def   ; el numero de baldosa que devolvio 0x4D65
	cp 092h		;4df2   ; 0x92 y 0x7C: los sillares del muelle
	jp z,no_se_puede		;4df4
	cp 07ch		;4df7
	jp z,no_se_puede		;4df9
	jp se_puede_pasar		;4dfc   ; lo demas se pisa
solidas_pantalla_1:		; Las once de la pantalla 1
	ld a,(0f883h)		;4dff   ; el numero de baldosa
	cp 050h		;4e02   ; 0x50, 0x3D, 0x3C, 0x01, 0x0D...
	jp z,no_se_puede		;4e04
	cp 03dh		;4e07
	jp z,no_se_puede		;4e09
	cp 03ch		;4e0c
	jp z,no_se_puede		;4e0e
	cp 001h		;4e11
	jp z,no_se_puede		;4e13
	cp 00dh		;4e16
	jp z,no_se_puede		;4e18
	cp 06bh		;4e1b   ; ...0x6B, 0x87, 0x35, 0x34, 0x3F y 0x32
	jp z,no_se_puede		;4e1d
	cp 087h		;4e20
	jp z,no_se_puede		;4e22
	cp 035h		;4e25
	jp z,no_se_puede		;4e27
	cp 034h		;4e2a
	jp z,no_se_puede		;4e2c
	cp 03fh		;4e2f
	jp z,no_se_puede		;4e31
	cp 032h		;4e34
	jp z,no_se_puede		;4e36
	jp se_puede_pasar		;4e39   ; lo demas se pisa
solidas_pantalla_2:		; Las siete de la pantalla 2
	ld a,(0f883h)		;4e3c   ; el numero de baldosa
	cp 061h		;4e3f   ; 0x61, 0x52, 0x3C, 0x0D...
	jp z,no_se_puede		;4e41
	cp 052h		;4e44
	jp z,no_se_puede		;4e46
	cp 03ch		;4e49
	jp z,no_se_puede		;4e4b
	cp 00dh		;4e4e
	jp z,no_se_puede		;4e50
	cp 05dh		;4e53   ; ...0x5D, 0x3D y 0x50
	jp z,no_se_puede		;4e55
	cp 03dh		;4e58
	jp z,no_se_puede		;4e5a
	cp 050h		;4e5d
	jp z,no_se_puede		;4e5f
	jp se_puede_pasar		;4e62   ; lo demas se pisa
solidas_pantalla_3:		; Las seis de la pantalla 3
	ld a,(0f883h)		;4e65   ; el numero de baldosa
	cp 03dh		;4e68   ; 0x3D, 0x50, 0x89...
	jp z,no_se_puede		;4e6a
	cp 050h		;4e6d
	jp z,no_se_puede		;4e6f
	cp 089h		;4e72
	jp z,no_se_puede		;4e74
	cp 03ch		;4e77   ; ...0x3C, 0x01 y 0xFD
	jp z,no_se_puede		;4e79
	cp 001h		;4e7c
	jp z,no_se_puede		;4e7e
	cp 0fdh		;4e81
	jp z,no_se_puede		;4e83
	jp se_puede_pasar		;4e86   ; lo demas se pisa
solidas_pantalla_4:		; Las siete de la pantalla 4
	ld a,(0f883h)		;4e89   ; el numero de baldosa
	cp 03dh		;4e8c   ; 0x3D, 0x50, 0x52, 0x0D...
	jp z,no_se_puede		;4e8e
	cp 050h		;4e91
	jp z,no_se_puede		;4e93
	cp 052h		;4e96
	jp z,no_se_puede		;4e98
	cp 00dh		;4e9b
	jp z,no_se_puede		;4e9d
	cp 03ch		;4ea0   ; ...0x3C, 0x01 y 0xFD
	jp z,no_se_puede		;4ea2
	cp 001h		;4ea5
	jp z,no_se_puede		;4ea7
	cp 0fdh		;4eaa
	jp z,no_se_puede		;4eac
	jp se_puede_pasar		;4eaf   ; lo demas se pisa
solidas_pantalla_5:		; Las seis de la pantalla 5
	ld a,(0f883h)		;4eb2   ; el numero de baldosa
	cp 03dh		;4eb5   ; 0x3D, 0x01, 0x50...
	jp z,no_se_puede		;4eb7
	cp 001h		;4eba
	jp z,no_se_puede		;4ebc
	cp 050h		;4ebf
	jp z,no_se_puede		;4ec1
	cp 00dh		;4ec4   ; ...0x0D, 0x3C y 0xFD
	jp z,no_se_puede		;4ec6
	cp 03ch		;4ec9
	jp z,no_se_puede		;4ecb
	cp 0fdh		;4ece
	jp z,no_se_puede		;4ed0
	jp se_puede_pasar		;4ed3   ; lo demas se pisa
solidas_pantalla_6:		; Las once de la pantalla 6
	ld a,(0f883h)		;4ed6   ; el numero de baldosa
	cp 050h		;4ed9   ; 0x50, 0x3D, 0x3C, 0x01, 0x5E...
	jp z,no_se_puede		;4edb
	cp 03dh		;4ede
	jp z,no_se_puede		;4ee0
	cp 03ch		;4ee3
	jp z,no_se_puede		;4ee5
	cp 001h		;4ee8
	jp z,no_se_puede		;4eea
	cp 05eh		;4eed
	jp z,no_se_puede		;4eef
	cp 052h		;4ef2   ; ...0x52, 0x61, 0x0D, 0x5C, 0x13 y 0x65
	jp z,no_se_puede		;4ef4
	cp 061h		;4ef7
	jp z,no_se_puede		;4ef9
	cp 00dh		;4efc
	jp z,no_se_puede		;4efe
	cp 05ch		;4f01
	jp z,no_se_puede		;4f03
	cp 013h		;4f06
	jp z,no_se_puede		;4f08
	cp 065h		;4f0b
	jp z,no_se_puede		;4f0d
	jp se_puede_pasar		;4f10   ; lo demas se pisa
solidas_pantalla_7:		; Las siete de la pantalla 7
	ld a,(0f883h)		;4f13   ; el numero de baldosa
	cp 001h		;4f16   ; 0x01, 0x3C, 0x52, 0x5D...
	jp z,no_se_puede		;4f18
	cp 03ch		;4f1b
	jp z,no_se_puede		;4f1d
	cp 052h		;4f20
	jp z,no_se_puede		;4f22
	cp 05dh		;4f25
	jp z,no_se_puede		;4f27
	cp 050h		;4f2a   ; ...0x50, 0x3D y 0x0D
	jp z,no_se_puede		;4f2c
	cp 03dh		;4f2f
	jp z,no_se_puede		;4f31
	cp 00dh		;4f34
	jp z,no_se_puede		;4f36
se_puede_pasar:		; No es solida: guarda la posicion y mira si hay puerta
	ld a,001h		;4f39   ; el campo 1 de la ficha es la X...
	call campo_del_objeto		;4f3b
	ld (0f883h),a		;4f3e
	inc hl			;4f41   ; ...y el 2, la Y
	ld a,(hl)			;4f42
	ld (0f884h),a		;4f43
	ld hl,(0f883h)		;4f46   ; las dos juntas en HL, para compararlas de una vez
mira_las_puertas:		; Segun la pantalla, decide si se cambia de escena
	ld a,(0f893h)		;4f49   ; cada pantalla tiene sus puertas y sus condiciones
	cp 000h		;4f4c   ; pantalla 0
	jp z,puertas_pantalla_0		;4f4e
	cp 001h		;4f51   ; pantalla 1
	jp z,puertas_pantalla_1		;4f53
	cp 002h		;4f56   ; pantalla 2
	jp z,puertas_pantalla_2		;4f58
	cp 003h		;4f5b   ; pantalla 3
	jp z,puertas_pantalla_3		;4f5d
	cp 004h		;4f60   ; pantalla 4
	jp z,puertas_pantalla_4		;4f62
	cp 005h		;4f65   ; pantalla 5
	jp z,puertas_pantalla_5		;4f67
	cp 006h		;4f6a   ; pantalla 6
	jp z,puertas_pantalla_6		;4f6c
	cp 007h		;4f6f   ; pantalla 7
	jp z,puertas_pantalla_7		;4f71
L_4F74:
	xor a			;4f74   ; sin puerta: se sigue como si nada
	ret			;4f75
puertas_pantalla_0:		; Del puerto se sale a la taberna o al agua
	ld a,001h		;4f76
	call campo_del_objeto		;4f78
	cp 030h		;4f7b   ; las columnas 0x30 a 0x34 son la puerta de la taberna
	jp c,L_4FDA		;4f7d
	cp 035h		;4f80
	jp nc,L_4FDA		;4f82
	ld a,(0f894h)		;4f85   ; y hay que estar andando hacia la derecha
	cp 001h		;4f88
	jp nz,L_4F74		;4f8a
	ld a,001h		;4f8d
	ld hl,09880h		;4f8f
cambia_de_pantalla:		; Deja puesta la pantalla A con el muñeco en HL
	ld (0f893h),a		;4f92
	ld (0f883h),hl		;4f95   ; HL trae la posicion de partida del muñeco
	xor a			;4f98   ; se reinician el contador lento y la marca de refresco
	ld (0f890h),a		;4f99
	ld (0f8a4h),a		;4f9c
	call borra_sprites		;4f9f   ; fuera los sprites de la pantalla anterior
	ld a,001h		;4fa2
	call campo_del_objeto		;4fa4
	ld a,(0f883h)		;4fa7
	ld (hl),a			;4faa
	inc hl			;4fab
	ld a,(0f884h)		;4fac
	ld (hl),a			;4faf
	call carga_pantalla		;4fb0   ; y se carga la pantalla nueva
recarga_punteros:		; Repone los tres punteros de trabajo desde su copia
	ld hl,(0f895h)		;4fb3   ; la ficha del protagonista
	ld (0f887h),hl		;4fb6
	ld hl,(0f897h)		;4fb9   ; sus sprites
	ld (0f87fh),hl		;4fbc
	ld hl,(0f899h)		;4fbf   ; y su tabla de atributos
	ld (0f881h),hl		;4fc2
	ret			;4fc5
borra_sprites:		; Manda todos los sprites fuera de la pantalla
	ld hl,01b00h		;4fc6   ; 0x1B00: la tabla de atributos de sprite
	ld de,01b80h		;4fc9
L_4FCC:
	ld a,0d1h		;4fcc   ; 0xD1 en la Y: fuera de la pantalla
	call 0004dh		;4fce   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;4fd1   ; cuatro bytes por sprite
	inc hl			;4fd2
	inc hl			;4fd3
	inc hl			;4fd4
	rst 20h			;4fd5
	jp nz,L_4FCC		;4fd6
	ret			;4fd9
L_4FDA:
	cp 070h		;4fda   ; las columnas 0x70 a 0x84 son la otra salida
	jp c,L_4FFF		;4fdc
	cp 085h		;4fdf
	jp nc,L_4FFF		;4fe1
	ld a,(0f89fh)		;4fe4   ; pero solo con tres pasos ya dados
	cp 003h		;4fe7
	jp c,L_4F74		;4fe9
	ld a,(0f894h)		;4fec
	cp 001h		;4fef
	jp nz,L_4F74		;4ff1
	call sube_estado		;4ff4
	ld a,002h		;4ff7
	ld hl,09008h		;4ff9
	jp cambia_de_pantalla		;4ffc
L_4FFF:
	cp 0f0h		;4fff   ; la columna 0xF0 es el borde: se sale por la derecha
	jp nz,puerta_de_la_travesia		;5001
	ld a,(0f894h)		;5004
	cp 001h		;5007
	jp nz,L_4F74		;5009
	ld a,006h		;500c
	ld hl,09880h		;500e
	jp cambia_de_pantalla		;5011
puertas_pantalla_1:		; Las salidas de la pantalla 1
	ld a,002h		;5014   ; el campo 2 de la ficha es la Y
	call campo_del_objeto		;5016
	cp 098h		;5019   ; fila 0x98: el suelo
	jp nz,L_502D		;501b
	ld a,(0f894h)		;501e   ; y andando hacia abajo, se pasa a la pantalla 0
	cp 005h		;5021
	jp nz,L_4F74		;5023
	xor a			;5026
	ld hl,03830h		;5027
	jp cambia_de_pantalla		;502a
L_502D:
	ld a,001h		;502d   ; --- las columnas 0x10 a 0x18 ---
	call campo_del_objeto		;502f
	cp 010h		;5032
	jp c,L_5054		;5034
	cp 019h		;5037
	jp nc,L_5054		;5039
	ld a,(0f89fh)		;503c   ; hacen falta al menos dos pasos dados
	cp 001h		;503f
	jp c,L_4F74		;5041
	ld a,(0f894h)		;5044   ; y hay que ir hacia la izquierda
	cp 007h		;5047
	jp nz,L_4F74		;5049
	ld a,004h		;504c
	ld hl,090f0h		;504e   ; se pasa a la pantalla 4
	jp cambia_de_pantalla		;5051
L_5054:
	cp 0e0h		;5054   ; --- las columnas 0xE0 a 0xE8 ---
	jp c,L_507C		;5056
	cp 0e9h		;5059
	jp nc,L_507C		;505b
	ld a,(0f89fh)		;505e   ; hacen falta al menos tres pasos
	cp 002h		;5061
	jp c,L_4F74		;5063
	ld a,(0f894h)		;5066   ; y hay que ir hacia la derecha
	cp 003h		;5069
	jp nz,L_4F74		;506b
	call baja_estado		;506e
	call baja_estado		;5071
	ld a,005h		;5074   ; se pasa a la pantalla 5
	ld hl,090f0h		;5076
	jp cambia_de_pantalla		;5079
L_507C:
	cp 080h		;507c   ; --- las columnas 0x80 a 0x90 ---
	jp c,L_4F74		;507e
	cp 091h		;5081
	jp nc,L_4F74		;5083
	ld a,(0f894h)		;5086   ; hacia arriba
	cp 001h		;5089
	jp nz,L_4F74		;508b
	ld a,003h		;508e   ; se pasa a la pantalla 3
	ld hl,098e8h		;5090
	jp cambia_de_pantalla		;5093
puertas_pantalla_2:		; Las salidas de la pantalla 2
	ld a,001h		;5096   ; el campo 1 de la ficha es la X
	call campo_del_objeto		;5098
	cp 011h		;509b   ; por debajo de la columna 0x11...
	jp nc,L_4F74		;509d
	ld a,(0f894h)		;50a0   ; ...y hacia la izquierda
	cp 007h		;50a3
	jp nz,L_4F74		;50a5
	call baja_estado		;50a8   ; baja el estado y se vuelve a la pantalla 0
	xor a			;50ab
	ld hl,05078h		;50ac
	jp cambia_de_pantalla		;50af
puertas_pantalla_3:		; Las salidas de la pantalla 3
	ld a,002h		;50b2
	call campo_del_objeto		;50b4
	cp 098h		;50b7   ; fila 0x98: el suelo
	jp nz,L_4F74		;50b9
	ld a,(0f894h)		;50bc   ; hacia abajo
	cp 005h		;50bf
	jp nz,L_4F74		;50c1
	ld a,001h		;50c4   ; se pasa a la pantalla 1
	ld hl,03888h		;50c6
	jp cambia_de_pantalla		;50c9
puertas_pantalla_4:		; Las salidas de la pantalla 4
	ld a,001h		;50cc
	call campo_del_objeto		;50ce
	cp 0f0h		;50d1   ; columna 0xF0: el borde derecho
	jp nz,L_4F74		;50d3
	ld a,(0f894h)		;50d6   ; hacia la derecha
	cp 003h		;50d9
	jp nz,L_4F74		;50db
	ld a,001h		;50de   ; se vuelve a la pantalla 1
	ld hl,09018h		;50e0
	jp cambia_de_pantalla		;50e3
puertas_pantalla_5:		; Las salidas de la pantalla 5
	ld a,001h		;50e6
	call campo_del_objeto		;50e8
	cp 0f0h		;50eb   ; columna 0xF0: el borde derecho
	jp nz,L_4F74		;50ed
	ld a,(0f894h)		;50f0   ; hacia la derecha
	cp 003h		;50f3
	jp nz,L_4F74		;50f5
	call sube_estado		;50f8   ; dos pasos de estado
	call sube_estado		;50fb
	ld a,001h		;50fe   ; se vuelve a la pantalla 1
	ld hl,090e0h		;5100
	jp cambia_de_pantalla		;5103
puertas_pantalla_6:		; Las salidas de la pantalla 6
	ld a,002h		;5106
	call campo_del_objeto		;5108
	cp 098h		;510b   ; fila 0x98: el suelo
	jp nz,L_4F74		;510d
	ld a,(0f894h)		;5110   ; hacia abajo
	cp 005h		;5113
	jp nz,L_4F74		;5115
	xor a			;5118   ; se vuelve a la pantalla 0
	ld hl,048f0h		;5119
	jp cambia_de_pantalla		;511c
sube_estado:		; El estado del protagonista avanza de 0 a 3 y vuelve
	call apunta_al_protagonista		;511f   ; antes hay que tener los punteros al dia
	ld a,003h		;5122   ; el campo 3 de la ficha es el estado
	call campo_del_objeto		;5124
	inc a			;5127
	ld (hl),a			;5128
	cp 004h		;5129   ; al llegar a 4 vuelve a cero
	ret nz			;512b
	xor a			;512c
	ld (hl),a			;512d
	ret			;512e
baja_estado:		; El estado del protagonista retrocede de 3 a 0
	call apunta_al_protagonista		;512f
	ld a,003h		;5132
	call campo_del_objeto		;5134   ; el campo 3 de la ficha
	cp 000h		;5137   ; en cero, se da la vuelta
	jp z,L_513F		;5139
	dec a			;513c
	ld (hl),a			;513d
	ret			;513e
L_513F:
	ld a,003h		;513f   ; y vuelve a 3
	ld (hl),a			;5141
	ret			;5142
puerta_de_la_travesia:		; La salida de la pantalla 0 que lleva al mapa ancho
	cp 0b0h		;5143   ; las columnas 0xB0 a 0xC8
	jp c,L_4F74		;5145
	cp 0c9h		;5148
	jp nc,L_4F74		;514a
	ld a,(0f8b9h)		;514d   ; hace falta haber reclutado marineros (0xF8B9) para poder zarpar
	cp 000h		;5150
	jp z,L_4F74		;5152
	ld a,(0f894h)		;5155   ; y andar hacia arriba
	cp 001h		;5158
	jp nz,L_4F74		;515a
	ld a,010h		;515d   ; el mapa ancho arranca por la columna 0x10
	ld (0f89dh),a		;515f
	ld a,007h		;5162
	ld hl,09880h		;5164
	jp cambia_de_pantalla		;5167
puertas_pantalla_7:		; Las salidas de la pantalla 7
	ld a,002h		;516a
	call campo_del_objeto		;516c
	cp 098h		;516f   ; fila 0x98: el suelo
	jp nz,L_518B		;5171
	ld a,(0f89dh)		;5174   ; con el mapa ancho sin correr del todo
	cp 011h		;5177
	jp nc,L_518B		;5179
	ld a,(0f894h)		;517c   ; hacia abajo
	cp 005h		;517f
	jp nz,L_518B		;5181
	xor a			;5184   ; se vuelve a la pantalla 0
	ld hl,050b0h		;5185
	jp cambia_de_pantalla		;5188
L_518B:
	ld a,001h		;518b   ; --- por la derecha del mapa ancho ---
	call campo_del_objeto		;518d
	cp 0d0h		;5190   ; a partir de la columna 0xD0
	jp c,L_4F74		;5192
	inc hl			;5195
	ld a,(hl)			;5196   ; y con la fila por encima de 0x79
	cp 079h		;5197
	jp nc,L_4F74		;5199
	ld a,(0f894h)		;519c   ; hacia abajo
	cp 003h		;519f
	jp nz,L_4F74		;51a1
	call baja_estado		;51a4
	ld a,006h		;51a7   ; se pasa a la pantalla 6
	ld hl,09880h		;51a9
	jp cambia_de_pantalla		;51ac
cuenta_atras:		; El plazo de la pantalla 3
	ld a,(0f8a0h)		;51af
	and a			;51b2
	jp nz,L_51FC		;51b3
	ld a,(0f893h)		;51b6   ; solo corre en la pantalla 3
	cp 003h		;51b9
	ret nz			;51bb
	ld a,(0f89ch)		;51bc
	cp 000h		;51bf
	ret nz			;51c1
	call marca_refresco		;51c2   ; el latido del reloj
	ld a,(0f8a1h)		;51c5   ; 0xF8A1 cuenta hasta 0xAC
	inc a			;51c8
	ld (0f8a1h),a		;51c9
	cp 064h		;51cc
	ret c			;51ce
	cp 0ach		;51cf
	jp nz,avanza_el_reloj		;51d1
	xor a			;51d4
	ld (0f8a1h),a		;51d5
	ld (0f8a2h),a		;51d8
	ld (0f890h),a		;51db
	ld a,(0aafeh)		;51de   ; 0xAAFD es la X de la primera ficha: donde esta el muñeco
	cp 054h		;51e1
	ret nc			;51e3
	call arrastra_a_la_izquierda		;51e4
	ld a,003h		;51e7
	ld (0f89ch),a		;51e9
	call sube_paso		;51ec
	call pinta_marco		;51ef
	ld a,003h		;51f2
	ld (0f8a3h),a		;51f4
	xor a			;51f7
	ld (0f8a4h),a		;51f8
	ret			;51fb
L_51FC:
	ld a,(0f893h)		;51fc
	cp 003h		;51ff
	ret nz			;5201
	jp pinta_marco		;5202
arrastra_a_la_izquierda:		; Empuja al muñeco hasta la columna 0x68
	ld a,(0aafdh)		;5205   ; 0xAAFD es la X del protagonista
	cp 068h		;5208   ; en la columna 0x68 ya esta donde tiene que estar
	jp nc,L_5219		;520a
	call espera_2000		;520d   ; mientras tanto, una pausa...
	call apunta_al_protagonista		;5210
	call L_47D8		;5213   ; ...y un paso hacia la izquierda
	jp arrastra_a_la_izquierda		;5216
L_5219:
	xor a			;5219   ; al llegar, se le deja con el estado 0
	jp espera_a_estado		;521a
avanza_el_reloj:		; Un paso del reloj de arena de la pantalla 3
	ld a,(0f890h)		;521d   ; 0xF890 cuenta los cuartos ya caidos
	inc a			;5220
	ld (0f890h),a		;5221
	cp 003h		;5224   ; al tercero se vuelve al primero
	jp nz,L_522F		;5226
	ld a,001h		;5229
	ld (0f890h),a		;522b
	ret			;522e
L_522F:
	ld a,(0f8a2h)		;522f   ; 0xF8A2 gira de 0 a 3
	inc a			;5232
	ld (0f8a2h),a		;5233
	cp 004h		;5236
	jp nz,L_523F		;5238
	xor a			;523b
	ld (0f8a2h),a		;523c
L_523F:
	cp 003h		;523f   ; el 3 se dibuja como el 1
	jp nz,L_5246		;5241
	ld a,001h		;5244
L_5246:
	ld (0f883h),a		;5246   ; tres dibujos de 0x50 bytes, uno por cuarto de reloj
	ld hl,0c012h		;5249
	ld de,00050h		;524c
L_524F:
	cp 000h		;524f   ; --- salta hasta el dibujo que toca ---
	jp z,L_525F		;5251
	add hl,de			;5254
	ld a,(0f883h)		;5255
	dec a			;5258
	ld (0f883h),a		;5259
	jp L_524F		;525c
L_525F:
	ld de,00e40h		;525f   ; 0x0E40: la baldosa donde se pinta el reloj
	ld bc,00050h		;5262   ; 0x50 bytes: diez baldosas
	call 0005ch		;5265   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ret			;5268
marca_refresco:		; Pone 0xF890 a uno y repinta el marco
	ld a,(0f890h)		;5269   ; solo la primera vez
	cp 000h		;526c
	ret nz			;526e
	inc a			;526f
	ld (0f890h),a		;5270
pinta_marco:		; Repinta las franjas de color del marco de la pantalla
	ld bc,00008h		;5273   ; 0x2638: color de una baldosa del marco
	ld hl,02638h		;5276
	ld a,0b1h		;5279   ; 0xB1: la pareja de colores del marco
	call 00056h		;527b   ; BIOS FILVRM - Fills VRAM with value
	ld bc,00008h		;527e   ; el mismo tramo en la tabla de patrones, con el dibujo 2
	ld hl,00638h		;5281
	ld a,002h		;5284
	call 00056h		;5286   ; BIOS FILVRM - Fills VRAM with value
	ld bc,00058h		;5289   ; 0x58 bytes: once baldosas seguidas
	ld hl,02e38h		;528c
	ld a,0b1h		;528f
	call 00056h		;5291   ; BIOS FILVRM - Fills VRAM with value
	ld bc,00008h		;5294
	ld hl,00e38h		;5297
	ld a,002h		;529a
	call 00056h		;529c   ; BIOS FILVRM - Fills VRAM with value
	ld bc,00050h		;529f   ; 0x0E40: la franja del reloj, en blanco
	ld hl,00e40h		;52a2
	xor a			;52a5
	call 00056h		;52a6   ; BIOS FILVRM - Fills VRAM with value
	ld bc,00020h		;52a9   ; y una baldosa mas de remate
	ld hl,00e68h		;52ac
	ld a,002h		;52af
	jp 00056h		;52b1   ; BIOS FILVRM - Fills VRAM with value
apunta_al_protagonista:		; Recalcula los tres punteros que dependen de 0xF89C
	ld hl,0aafdh		;52b4   ; la ficha: once bytes por estado
	ld de,0000bh		;52b7
	call avanza_por_estado		;52ba
	ld (0f895h),hl		;52bd   ; y se guarda para quien la necesite
	ld hl,09e55h		;52c0   ; los sprites: 0x168 bytes por estado
	ld de,00168h		;52c3
	call avanza_por_estado		;52c6
	ld (0f897h),hl		;52c9
	ld hl,038a0h		;52cc   ; y la tabla de atributos, siempre en 0x38A0
	ld (0f899h),hl		;52cf
	jp recarga_punteros		;52d2
avanza_por_estado:		; HL += DE, repetido 0xF89C veces
	ld a,(0f89ch)		;52d5   ; 0xF89C es el estado, o sea el juego de sprites
L_52D8:
	ld (0f883h),a		;52d8   ; --- un paso por cada unidad de estado ---
	cp 000h		;52db   ; con cero pasos, HL se queda como esta
	ret z			;52dd
	add hl,de			;52de
	ld a,(0f883h)		;52df
	dec a			;52e2
	jp L_52D8		;52e3
pinta_el_marcador:		; Pinta o borra el marco segun la pantalla
	ld a,(0f8a4h)		;52e6   ; una sola vez por cambio
	cp 000h		;52e9
	ret nz			;52eb
	inc a			;52ec
	ld (0f8a4h),a		;52ed
	ld a,(0f8a3h)		;52f0   ; 0xF8A3 dice en que pantalla toca marco
	ld e,a			;52f3
	ld a,(0f893h)		;52f4
	cp 000h		;52f7
	jp z,borra_letrero		;52f9
	cp e			;52fc
	jp nz,borra_letrero		;52fd
pinta_letrero:		; Sube los patrones del letrero a la baldosa 0xF9
	ld hl,0c102h		;5300
	ld de,007c8h		;5303
	ld bc,00038h		;5306
	call vuelca_con_color		;5309
	jp borra_sprites		;530c
borra_letrero:		; Deja la zona del letrero en blanco
	ld bc,00038h		;530f
	ld hl,00fc8h		;5312
	xor a			;5315
	call 00056h		;5316   ; BIOS FILVRM - Fills VRAM with value
	ld bc,00038h		;5319
	ld hl,02fc8h		;531c
	ld a,0ffh		;531f
	call 00056h		;5321   ; BIOS FILVRM - Fills VRAM with value
	ld bc,00008h		;5324
	ld hl,02fe8h		;5327
	ld a,0eeh		;532a
	call 00056h		;532c   ; BIOS FILVRM - Fills VRAM with value
	ld bc,00038h		;532f
	ld hl,017c8h		;5332
	xor a			;5335
	call 00056h		;5336   ; BIOS FILVRM - Fills VRAM with value
	ld bc,00038h		;5339
	ld hl,037c8h		;533c
	ld a,0ffh		;533f
	call 00056h		;5341   ; BIOS FILVRM - Fills VRAM with value
	ld bc,00008h		;5344
	ld hl,037e8h		;5347
	ld a,0eeh		;534a
	jp 00056h		;534c   ; BIOS FILVRM - Fills VRAM with value
mira_la_llave:		; En la pantalla 4, si se llega a la casilla de la llave
	ld a,(0f893h)		;534f   ; solo en la pantalla 4
	cp 004h		;5352
	ret nz			;5354
	ld a,(0f89ch)		;5355   ; y con el estado 3
	cp 003h		;5358
	ret nz			;535a
	ld a,(0f8a0h)		;535b   ; con el marcador ya en 1 no se repite
	cp 001h		;535e
	ret z			;5360
	ld a,001h		;5361
	call campo_del_objeto		;5363
	cp 040h		;5366   ; columna 0x40, fila 0x88
	jp nz,L_5378		;5368
	inc hl			;536b
	ld a,(hl)			;536c
	cp 088h		;536d
	jp nz,L_5378		;536f
L_5372:
	call sube_marcador		;5372   ; sube el marcador...
	jp carga_pantalla		;5375   ; ...y recarga la pantalla, que ha cambiado
L_5378:
	ld a,001h		;5378
	call campo_del_objeto		;537a
	cp 048h		;537d   ; o columna 0x48, fila 0x80
	ret nz			;537f
	inc hl			;5380
	ld a,(hl)			;5381
	cp 080h		;5382
	ret nz			;5384
	jp L_5372		;5385
mira_el_permiso:		; En la pantalla 6, la audiencia en la corte
	ld a,(0f893h)		;5388   ; solo en la pantalla 6
	cp 006h		;538b
	ret nz			;538d
	call apunta_al_protagonista		;538e
	ld a,002h		;5391   ; hay que estar en la columna 0x48
	call campo_del_objeto		;5393
	cp 048h		;5396
	ret nz			;5398
	ld a,(0f89ch)		;5399   ; sin estado, la audiencia se acaba
	cp 000h		;539c
	jp z,fin_de_la_travesia		;539e
	cp 002h		;53a1   ; con estado 2 y tres de marcador...
	jp nz,L_53B4		;53a3
	ld a,(0f8a0h)		;53a6   ; ...y con al menos tres pasos dados
	cp 003h		;53a9
	ret c			;53ab
	sub 002h		;53ac
	ld (0f8b9h),a		;53ae   ; ...los marineros reclutados son el marcador menos dos
	call sube_marcador		;53b1
L_53B4:
	ld a,(0f89fh)		;53b4   ; --- comprueba que los pasos cuadran con el marcador ---
	ld e,a			;53b7
	ld a,(0f8a0h)		;53b8
	cp e			;53bb
	ret nz			;53bc
	ld a,002h		;53bd   ; el campo 2 de la ficha: la Y
	call campo_del_objeto		;53bf
	sub 004h		;53c2   ; se le suben cuatro pixeles
	ld (hl),a			;53c4
	ld a,003h		;53c5
	call espera_a_estado		;53c7   ; y se espera a que el estado llegue a 3
	ld a,(0f89fh)		;53ca   ; con un solo paso, una escena
	cp 001h		;53cd
	jp z,L_5408		;53cf
	cp 002h		;53d2   ; con dos, otra
	jp z,L_5413		;53d4
	ld a,(0f89ch)		;53d7
	cp 002h		;53da
	jp z,L_53F7		;53dc
	ld a,0ffh		;53df   ; con 0xFF el protagonista sale de juego
	ld (0f89ch),a		;53e1
	call borra_sprites		;53e4
	ld a,002h		;53e7
	ld (0f893h),a		;53e9   ; y se va a la pantalla 2
	call carga_pantalla		;53ec
	ld a,001h		;53ef
	ld (0f8a6h),a		;53f1
	jp sube_paso		;53f4
L_53F7:
	call limpia_estado		;53f7   ; --- con dos de estado, a la pantalla 5 ---
	ld a,002h		;53fa
	ld (hl),a			;53fc
	call borra_sprites		;53fd
	ld a,005h		;5400
	ld (0f893h),a		;5402
	jp carga_pantalla		;5405
L_5408:
	call limpia_estado		;5408
	ld a,003h		;540b
	ld hl,05068h		;540d
	jp cambia_de_pantalla		;5410
L_5413:
	call limpia_estado		;5413
	ld a,004h		;5416
	ld hl,07858h		;5418
	jp cambia_de_pantalla		;541b
limpia_estado:		; Deja el estado del protagonista a cero
	xor a			;541e   ; 0xF8A3, 0xF89C y 0xF890, todos a cero
	ld (0f8a3h),a		;541f
	ld (0f89ch),a		;5422
	ld (0f890h),a		;5425
	call apunta_al_protagonista		;5428
	ld a,003h		;542b   ; el campo 3 de la ficha, tambien
	call campo_del_objeto		;542d
	xor a			;5430
	ld (hl),a			;5431
	ret			;5432
espera_a_estado:		; Deja correr el juego hasta que el estado del protagonista sea A
	ld (0f883h),a		;5433   ; el estado al que hay que llegar
	call apunta_al_protagonista		;5436
L_5439:
	ld a,003h		;5439   ; --- hasta que el campo 3 de la ficha valga eso ---
	call campo_del_objeto		;543b
	ld e,a			;543e
	ld a,(0f883h)		;543f
	cp e			;5442
	ret z			;5443
	call espera_2000		;5444   ; mientras tanto, la pausa, un paso de estado y el dibujo
	call sube_estado		;5447
	call apunta_al_protagonista		;544a
	call pinta_al_protagonista		;544d
	jp L_5439		;5450
anima_la_puerta:		; La puerta de la pantalla 4, que se abre y se cierra
	ld a,(0f893h)		;5453   ; solo en la pantalla 4
	cp 004h		;5456
	ret nz			;5458
	ld a,(0f89ch)		;5459
	cp 000h		;545c
	ret nz			;545e
	ld hl,01a66h		;545f   ; 0x1A66: la baldosa de la puerta
	call 0004ah		;5462   ; BIOS RDVRM - Reads the content of VRAM | RDVRM: lo que hay puesto ahora
	ld (0f883h),a		;5465
	cp 06bh		;5468   ; alterna entre las baldosas 0x6B y 0x6C
	jp z,L_547B		;546a
	ld a,(0f883h)		;546d
	cp 06ch		;5470
	ret nz			;5472
	ld a,06bh		;5473
L_5475:
	ld hl,01a66h		;5475
	jp 0004dh		;5478   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
L_547B:
	ld a,06ch		;547b
	jp L_5475		;547d
mira_el_cofre:		; En la pantalla 4, el cofre de la columna 0x78
	ld a,(0f893h)		;5480   ; solo en la pantalla 4
	cp 004h		;5483
	ret nz			;5485
	ld a,(0f890h)		;5486   ; la primera vez hay que pintar el cofre
	cp 000h		;5489
	jp z,abre_el_cofre		;548b
	ld a,(0f89ch)		;548e   ; con el protagonista fuera de juego, nada
	cp 000h		;5491
	ret nz			;5493
	ld a,(0f8a0h)		;5494   ; y con dos de marcador, ya esta hecho
	cp 002h		;5497
	ret nc			;5499
	call apunta_al_protagonista		;549a
	ld a,002h		;549d   ; la columna: 0x78
	call campo_del_objeto		;549f
	cp 078h		;54a2
	ret nz			;54a4
	inc hl			;54a5   ; y la fila: 1
	ld a,(hl)			;54a6
	cp 001h		;54a7
	ret nz			;54a9
	call arrastra_a_la_derecha		;54aa   ; se arrastra al muñeco hasta el cofre
	ld a,004h		;54ad   ; y se pasa al estado 4
	ld (0f8a3h),a		;54af
	xor a			;54b2
	ld (0f8a4h),a		;54b3
	call sube_paso		;54b6
	ld a,001h		;54b9
	ld (0f89ch),a		;54bb
L_54BE:
	ld hl,0911ah		;54be   ; 0x911A: la baldosa del cofre en la tabla de nombres
	ld a,04fh		;54c1
	ld (hl),a			;54c3
	ld de,00020h		;54c4   ; 0x20: una fila
	add hl,de			;54c7
	ld a,04fh		;54c8
	ld (hl),a			;54ca
	add hl,de			;54cb
	ld a,04ch		;54cc
	ld (hl),a			;54ce
	inc hl			;54cf
	ld a,062h		;54d0
	ld (hl),a			;54d2
	inc hl			;54d3
	ld a,036h		;54d4
	ld (hl),a			;54d6
	inc hl			;54d7
	ld a,062h		;54d8
	ld (hl),a			;54da
	jp carga_pantalla		;54db
arrastra_a_la_derecha:		; Empuja al muñeco hasta la columna 0x54
	ld a,(0aafdh)		;54de   ; 0xAAFD es la X del protagonista
	cp 054h		;54e1   ; la columna 0x54 es el destino
	ret z			;54e3
	call espera_2000		;54e4   ; mientras no llegue: pausa y un paso a la derecha
	call apunta_al_protagonista		;54e7
	call L_480A		;54ea
	jp arrastra_a_la_derecha		;54ed
abre_el_cofre:		; Pinta el cofre abierto y su contenido
	inc a			;54f0
	ld (0f890h),a		;54f1
	ld a,(0f89fh)		;54f4   ; con un solo paso dado, el cofre sale vacio
	cp 001h		;54f7
	jp nz,L_54BE		;54f9
	ld hl,0b85fh		;54fc   ; 0x17B8 y 0x37B8: patron y color del cofre abierto
	ld de,017b8h		;54ff
	ld bc,00010h		;5502
	call 0005ch		;5505   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld hl,0b86fh		;5508
	ld de,037b8h		;550b
	ld bc,00010h		;550e
	call 0005ch		;5511   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld hl,01a25h		;5514   ; 0x1A25: la baldosa del contenido
	ld a,0f7h		;5517
	call 0004dh		;5519   ; BIOS WRTVRM - Writes data in VRAM
	ld de,00020h		;551c
	add hl,de			;551f
	ld a,0f8h		;5520
	call 0004dh		;5522   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;5525
	ld a,06ah		;5526
	call 0004dh		;5528   ; BIOS WRTVRM - Writes data in VRAM
	ld a,(0f8a0h)		;552b
	cp 001h		;552e
	ret z			;5530
	inc hl			;5531
	ld a,062h		;5532
	call 0004dh		;5534   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;5537
	ld a,036h		;5538
	call 0004dh		;553a   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;553d
	ld a,062h		;553e
	jp 0004dh		;5540   ; BIOS WRTVRM - Writes data in VRAM
sube_paso:		; 0xF89F++: el contador de pasos dados de la aventura
	ld a,(0f89fh)		;5543
	inc a			;5546
	ld (0f89fh),a		;5547
	ret			;554a
mira_el_barril:		; En la pantalla 5, el barril de la columna 0x60
	ld a,(0f893h)		;554b   ; solo en la pantalla 5
	cp 005h		;554e
	ret nz			;5550
	ld a,(0f89ch)		;5551   ; y con el estado 1
	cp 001h		;5554
	ret nz			;5556
	ld a,(0f8a0h)		;5557   ; con dos de marcador ya esta hecho
	cp 002h		;555a
	ret z			;555c
	call apunta_al_protagonista		;555d
	ld a,003h		;5560   ; el estado tiene que ser 0
	call campo_del_objeto		;5562
	cp 000h		;5565
	ret nz			;5567
	ld a,001h		;5568
	call campo_del_objeto		;556a   ; columna por debajo de 0xA9
	cp 0a9h		;556d
	ret nc			;556f
	inc hl			;5570   ; y fila por encima de 0x65
	ld a,(hl)			;5571
	cp 065h		;5572
	ret nc			;5574
	call sube_marcador		;5575   ; sube el marcador
	ld hl,09406h		;5578   ; y se cambian dos baldosas de la pantalla 6
	ld a,05dh		;557b
	ld (hl),a			;557d
	inc hl			;557e
	ld a,044h		;557f
	ld (hl),a			;5581
	jp carga_pantalla		;5582
sube_marcador:		; 0xF8A0++
	ld a,(0f8a0h)		;5585
	inc a			;5588
	ld (0f8a0h),a		;5589
	ret			;558c
escena_de_la_taberna:		; Lo que pasa en la pantalla 5 al llegar a la barra
	ld a,(0f893h)		;558d   ; solo en la pantalla 5
	cp 005h		;5590
	ret nz			;5592
	ld a,(0f8a0h)		;5593   ; y con menos de tres de marcador
	cp 003h		;5596
	ret nc			;5598
	ld a,(0f890h)		;5599   ; la primera vez hay que pintar la barra
	cp 000h		;559c
	jp z,pinta_la_barra		;559e
	ld a,(0f89ch)		;55a1   ; el protagonista tiene que estar en juego
	cp 000h		;55a4
	ret nz			;55a6
	call apunta_al_protagonista		;55a7
	ld a,001h		;55aa
	call campo_del_objeto		;55ac
	cp 060h		;55af   ; columna 0x60
	ret nz			;55b1
	inc hl			;55b2
	ld a,(hl)			;55b3
	cp 065h		;55b4   ; y fila por encima de 0x65
	ret nc			;55b6
	ld a,002h		;55b7   ; se espera a que el estado llegue a 2
	call espera_a_estado		;55b9
	ld a,005h		;55bc
	ld (0f8a3h),a		;55be
	xor a			;55c1
	ld (0f8a4h),a		;55c2
	ld a,(0f8a5h)		;55c5   ; y de paso se voltean los patrones, una de cada dos veces
	cp 000h		;55c8
	call z,alterna_volteo		;55ca
	call sube_paso		;55cd
	ld a,002h		;55d0
	ld (0f89ch),a		;55d2
	ld hl,093a6h		;55d5   ; se cambian seis baldosas de la pantalla 6
	ld de,0001fh		;55d8   ; 0x1F: una fila menos una columna
	ld a,065h		;55db
	ld (hl),a			;55dd
	inc hl			;55de
	ld a,063h		;55df
	ld (hl),a			;55e1
	add hl,de			;55e2
	ld a,065h		;55e3
	ld (hl),a			;55e5
	inc hl			;55e6
	ld a,002h		;55e7
	ld (hl),a			;55e9
	add hl,de			;55ea
	ld a,065h		;55eb
	ld (hl),a			;55ed
	inc hl			;55ee
	ld (hl),a			;55ef
	ld hl,09406h		;55f0   ; y dos mas en 0x9406
	ld a,05eh		;55f3
	ld (hl),a			;55f5
	inc hl			;55f6
	ld a,064h		;55f7
	ld (hl),a			;55f9
	jp carga_pantalla		;55fa
pinta_la_barra:		; Sube los patrones de la barra a la baldosa 0xF4
	inc a			;55fd   ; la primera vez y solo una
	ld (0f890h),a		;55fe
	ld hl,0c172h		;5601   ; 0x28 bytes: cinco baldosas
	ld de,007a0h		;5604
	ld bc,00028h		;5607
	jp vuelca_con_color		;560a
alterna_volteo:		; Voltea los patrones una vez si, otra no
	ld a,(0f8a5h)		;560d   ; 0xF8A5 alterna entre 0 y 1
	inc a			;5610
	ld (0f8a5h),a		;5611
	cp 001h		;5614   ; en la primera se voltea...
	jp z,voltea_los_patrones		;5616
	xor a			;5619   ; ...y en la segunda se vuelve a dejar como estaba
	ld (0f8a5h),a		;561a
voltea_los_patrones:		; Da la vuelta a los patrones de 0xC102 a 0xC138
	ld hl,0c102h		;561d   ; 0x37 bytes: siete baldosas menos una
	ld de,0c139h		;5620
	jp voltea_bits		;5623
escena_de_la_nave:		; Lo que pasa en la pantalla 2 al llegar a la nave
	ld a,(0f893h)		;5626   ; solo en la pantalla 2
	cp 002h		;5629
	ret nz			;562b
	ld a,(0f89ch)		;562c   ; con el estado 4 ya esta hecho
	cp 004h		;562f
	jp z,L_565A		;5631
	ld a,(0f8a6h)		;5634   ; o con la escena ya lanzada
	cp 001h		;5637
	jp z,L_565A		;5639
	ld a,(0f89ch)		;563c   ; hace falta el estado 2
	cp 002h		;563f
	ret nz			;5641
	call apunta_al_protagonista		;5642
	ld a,001h		;5645
	call campo_del_objeto		;5647
	cp 0bch		;564a   ; columna 0xBC, fila 0x90
	ret nz			;564c
	inc hl			;564d
	ld a,(hl)			;564e
	cp 090h		;564f
	ret nz			;5651
	ld a,001h		;5652   ; se lanza la escena
	ld (0f8a6h),a		;5654
	call borra_sprites		;5657   ; y fuera los sprites
L_565A:
	ld hl,0c1c2h		;565a   ; repinta el letrero de la nave
	ld de,00778h		;565d
	ld bc,00050h		;5660   ; 0x50 bytes: diez baldosas
	call vuelca_con_color		;5663
	ld hl,01a78h		;5666   ; y retoca las baldosas del mastil
	ld a,0f7h		;5669
	call 0004dh		;566b   ; BIOS WRTVRM - Writes data in VRAM
	ld hl,01a39h		;566e
	ld de,0001fh		;5671   ; 0x1F: una fila menos una columna
	ld a,0f0h		;5674
	call 0004dh		;5676   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;5679
	ld a,0efh		;567a
	call 0004dh		;567c   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;567f
	ld a,0f2h		;5680
	call 0004dh		;5682   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;5685
	ld a,0f1h		;5686
	call 0004dh		;5688   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;568b
	ld a,0f4h		;568c
	call 0004dh		;568e   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;5691
	ld a,0f3h		;5692
	call 0004dh		;5694   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;5697
	ld a,0f6h		;5698
	call 0004dh		;569a   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;569d
	ld a,0f5h		;569e
	call 0004dh		;56a0   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;56a3
	ld a,0f8h		;56a4
	jp 0004dh		;56a6   ; BIOS WRTVRM - Writes data in VRAM
paso_de_escena:		; Un paso de la escena automatica de 0xF8A7
	ld a,(0f8a7h)		;56a9   ; con 0xF8A7 a cero, la escena no ha empezado
	cp 000h		;56ac
	jp z,espera_al_gatillo		;56ae
	call apunta_al_protagonista		;56b1   ; los punteros al dia antes de nada
	call que_toca_ahora		;56b4   ; lo que toque en este paso
	ld a,(0f8a7h)		;56b7   ; y un paso mas
	inc a			;56ba
	ld (0f8a7h),a		;56bb
	ret			;56be
que_toca_ahora:		; Elige el paso de escena segun 0xF8A7
	ld a,(0f8a7h)		;56bf   ; el numero de paso
	cp 001h		;56c2   ; paso 1: sube el estado
	jp z,sube_estado		;56c4
	cp 002h		;56c7   ; pasos 2 y 3: dos pixeles a la izquierda
	jp z,dos_a_la_izquierda		;56c9
	cp 003h		;56cc
	jp z,dos_a_la_izquierda		;56ce
	cp 004h		;56d1   ; paso 4: baja el estado
	jp z,baja_estado		;56d3
	cp 005h		;56d6   ; paso 5: subir por la escala
	jp z,paso_de_subida		;56d8
	cp 006h		;56db   ; paso 6: baja el estado
	jp z,baja_estado		;56dd
	cp 007h		;56e0   ; paso 7: bajar por la escala
	jp z,paso_de_bajada		;56e2
	cp 008h		;56e5   ; paso 8: el tramo final
	jp z,paso_final		;56e7
	ret			;56ea
espera_al_gatillo:		; Espera a que se pulse para arrancar la escena
	ld a,(0f89fh)		;56eb
	cp 00bh		;56ee   ; con once pasos dados no hay escena que esperar
	ret z			;56f0
	xor a			;56f1
	call lee_gatillo		;56f2   ; se mira el gatillo
	and a			;56f5
	ret z			;56f6
	ld a,004h		;56f7   ; el protagonista pasa al estado 4
	ld (0f89ch),a		;56f9
	call apunta_al_protagonista		;56fc   ; punteros al dia
	ld a,001h		;56ff
	call campo_del_objeto		;5701
	ld a,068h		;5704   ; y el muñeco se coloca en la columna 0x68, fila 0x10
	ld (hl),a			;5706
	inc hl			;5707
	ld a,010h		;5708
	ld (hl),a			;570a
	inc hl			;570b
	ld a,003h		;570c   ; con el estado 3
	ld (hl),a			;570e
	ld a,(0f8a7h)		;570f   ; y arranca la escena
	inc a			;5712
	ld (0f8a7h),a		;5713
	ret			;5716
paso_de_subida:		; El muñeco sube por la escala, dos pixeles por vuelta
	ld a,(0f8a9h)		;5717   ; 0xF8A9 cuenta los pasos cortos
	inc a			;571a
	ld (0f8a9h),a		;571b
	cp 004h		;571e   ; cada cuatro...
	jp nz,L_5748		;5720
	ld a,001h		;5723
	ld (0f8a9h),a		;5725
	ld a,(0f8a8h)		;5728   ; ...0xF8A8 cuenta los largos
	inc a			;572b
	ld (0f8a8h),a		;572c
	cp 004h		;572f   ; y cada cuatro de esos, dos pasos hacia abajo
	jp nz,L_5748		;5731
	call dos_a_la_derecha		;5734
dos_a_la_derecha:		; X += 4 en la ficha
	ld a,002h		;5737
	call campo_del_objeto		;5739
	add a,004h		;573c
	ld (hl),a			;573e
	ret			;573f
paso_atras:		; 0xF8A7--: se repite el paso de escena
	ld a,(0f8a7h)		;5740
	dec a			;5743
	ld (0f8a7h),a		;5744
	ret			;5747
L_5748:
	call paso_atras		;5748   ; mientras tanto se repite el paso y se baja
	call dos_a_la_derecha		;574b
	call dos_a_la_derecha		;574e
	ld a,(0f8a9h)		;5751
	cp 001h		;5754
	ret z			;5756
dos_a_la_izquierda:		; X -= 4 en la ficha
	ld a,001h		;5757
	call campo_del_objeto		;5759
	sub 004h		;575c
	ld (hl),a			;575e
	ret			;575f
paso_de_bajada:		; El muñeco baja por la escala
	ld a,(0f8a9h)		;5760   ; 0xF8A9 cuenta los pasos cortos
	inc a			;5763
	ld (0f8a9h),a		;5764
	cp 003h		;5767   ; cada tres...
	jp nz,L_577D		;5769
	ld a,001h		;576c
	ld (0f8a9h),a		;576e
	ld a,(0f8a8h)		;5771   ; ...0xF8A8 cuenta los largos
	inc a			;5774
	ld (0f8a8h),a		;5775
	cp 008h		;5778   ; y a los ocho, se acaba
	jp z,L_579A		;577a
L_577D:
	call paso_atras		;577d   ; se repite el paso
	ld a,(0f8a9h)		;5780
	cp 001h		;5783   ; alternando derecha e izquierda
	jp z,cuatro_a_la_derecha		;5785
	jp dos_a_la_derecha		;5788
paso_final:		; El ultimo tramo de la escena
	ld a,(0f8a8h)		;578b
	inc a			;578e   ; 0xF8A8 cuenta hasta once
	ld (0f8a8h),a		;578f
	cp 00bh		;5792
	jp nz,L_57A2		;5794
	call sube_marcador		;5797   ; y al llegar, sube el marcador
L_579A:
	xor a			;579a   ; los dos contadores a cero
	ld (0f8a8h),a		;579b
	ld (0f8a9h),a		;579e
	ret			;57a1
L_57A2:
	call paso_atras		;57a2   ; y mientras tanto, cuatro pixeles a la derecha
	call cuatro_a_la_derecha		;57a5
cuatro_a_la_derecha:		; X += 4 en la ficha
	ld a,001h		;57a8
	call campo_del_objeto		;57aa
	add a,004h		;57ad
	ld (hl),a			;57af
	ret			;57b0
arranca_la_escena:		; Con cuatro puntos de marcador, la escena de la nave
	ld a,(0f8a0h)		;57b1   ; hacen falta cuatro de marcador
	cp 004h		;57b4
	ret c			;57b6
	ld a,(0f8a7h)		;57b7   ; y que no haya escena en marcha
	cp 000h		;57ba
	ret nz			;57bc
	xor a			;57bd   ; se espera al gatillo
	call lee_mando		;57be
	and a			;57c1
	ret z			;57c2
	ld a,002h		;57c3   ; el protagonista pasa al estado 2
	ld (0f89ch),a		;57c5
	call apunta_al_protagonista		;57c8
	ld a,002h		;57cb   ; y aparece en la columna 0x78, fila 0xD8
	ld hl,078d8h		;57cd
	call cambia_de_pantalla		;57d0
	ld a,009h		;57d3   ; con la escena en el paso 9: el que la termina
	ld (0f8a7h),a		;57d5
	ret			;57d8
el_gran_salto:		; En la pantalla 7, el paso al barco
	ld a,(0f893h)		;57d9
	cp 007h		;57dc
	ret nz			;57de
	xor a			;57df   ; hay que pulsar el gatillo
	call lee_gatillo		;57e0
	and a			;57e3
	ret z			;57e4
	ld a,(0f8bah)		;57e5   ; y no haber saltado dieciseis veces ya
	cp 010h		;57e8
	ret z			;57ea
	ld a,(0f8a5h)		;57eb
	cp 000h		;57ee
	call z,alterna_volteo		;57f0
	call apunta_al_protagonista		;57f3
	ld a,003h		;57f6
	call campo_del_objeto		;57f8
	cp 001h		;57fb
	ret nz			;57fd
	ld bc,0aafdh		;57fe   ; la ficha del protagonista
	call baldosa_de		;5801
	ld (0f885h),hl		;5804
	call 0004ah		;5807   ; BIOS RDVRM - Reads the content of VRAM | la baldosa donde esta: si es 0x3F, hay tabla
	cp 03fh		;580a
	ret nz			;580c
	call donde_esta_el_barco		;580d
	call pinta_progreso		;5810
	ld a,(0f8bah)		;5813
	cp 000h		;5816
	call z,sube_marcador		;5818
	call pinta_letrero		;581b
	ld hl,0c262h		;581e   ; dos baldosas de color y una franja de 0x10 en la 0x2FF0
	ld de,02fc8h		;5821
	ld bc,00008h		;5824
	call 0005ch		;5827   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld hl,0c26ah		;582a
	ld de,037d0h		;582d
	ld bc,00008h		;5830
	call 0005ch		;5833   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld hl,02ff0h		;5836
	ld bc,00010h		;5839
	ld a,018h		;583c
	call 00056h		;583e   ; BIOS FILVRM - Fills VRAM with value
	ld hl,(0f885h)		;5841   ; y se pintan las siete baldosas del tablon
	dec hl			;5844
	ld a,0ffh		;5845
	call 0004dh		;5847   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;584a
	ld a,0f9h		;584b
	call 0004dh		;584d   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;5850
	ld a,0feh		;5851
	call 0004dh		;5853   ; BIOS WRTVRM - Writes data in VRAM
	ld de,0001fh		;5856
	add hl,de			;5859
	ld a,0fah		;585a
	call 0004dh		;585c   ; BIOS WRTVRM - Writes data in VRAM
	ld de,00020h		;585f
	add hl,de			;5862
	ld a,0fbh		;5863
	call 0004dh		;5865   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;5868
	ld a,0fch		;5869
	call 0004dh		;586b   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;586e
	ld a,0fdh		;586f
	call 0004dh		;5871   ; BIOS WRTVRM - Writes data in VRAM
	ld a,004h		;5874
	ld (0f89ch),a		;5876
	ld bc,0ab29h		;5879   ; 0xAB29 es la ficha del tablon: X 0xF0, Y 0x50
	ld a,0f0h		;587c
	ld (bc),a			;587e
	inc bc			;587f
	ld a,050h		;5880
	ld (bc),a			;5882
	inc bc			;5883
	xor a			;5884
	ld (bc),a			;5885
	call apunta_al_protagonista		;5886
	ld a,(0f89dh)		;5889   ; el tablon corre hasta la columna 0x1D
L_588C:
	ld (0f883h),a		;588c   ; --- retrocede el mapa ancho hasta la columna 0x1D ---
	cp 01dh		;588f
	jp c,L_58A1		;5891
	call dos_a_la_izquierda		;5894   ; dos pasos a la izquierda por vuelta
	call dos_a_la_izquierda		;5897
	ld a,(0f883h)		;589a
	dec a			;589d
	jp L_588C		;589e
L_58A1:
	ld a,008h		;58a1   ; pantalla 8: la del salto
	ld (0f893h),a		;58a3
L_58A6:
	call espera_2000		;58a6   ; --- espera a que el muñeco llegue al tablon ---
	call apunta_al_protagonista		;58a9
	call L_480A		;58ac
	ld a,(0aafdh)		;58af
	ld e,a			;58b2
	ld a,(0ab29h)		;58b3
	cp e			;58b6
	jp nz,L_58A6		;58b7
	ld hl,(0ab29h)		;58ba   ; la posicion del tablon pasa a la ficha siguiente
	ld (0ab34h),hl		;58bd
	call borra_sprites		;58c0
	ld hl,0a55dh		;58c3   ; el sprite grande, a la tabla de patrones de sprite
	ld de,03850h		;58c6
	ld bc,00050h		;58c9
	call 0005ch		;58cc   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld hl,(0f8b1h)		;58cf   ; y el sprite de mar que toque
	ld de,038a0h		;58d2
	ld bc,00030h		;58d5
	call 0005ch		;58d8   ; BIOS LDIRVM - Block transfers to VRAM from memory
L_58DB:
	call pinta_el_tablon		;58db   ; --- el tablon avanza cuatro pixeles por vuelta ---
	call espera_2000		;58de
	ld a,(0ab34h)		;58e1
	add a,004h		;58e4
	ld (0ab34h),a		;58e6
	ld a,(0f89dh)		;58e9
	ld (0f883h),a		;58ec
	cp 01dh		;58ef
	jp c,L_5904		;58f1
	ld bc,0ab34h		;58f4
	call baldosa_de		;58f7
	inc hl			;58fa
	inc hl			;58fb
	call 0004ah		;58fc   ; BIOS RDVRM - Reads the content of VRAM
	cp 04fh		;58ff
	jp z,L_590C		;5901
L_5904:
	ld a,(0ab34h)		;5904   ; hasta la columna 0xF0
	cp 0f0h		;5907
	jp nz,L_58DB		;5909
L_590C:
	ld a,007h		;590c   ; y de vuelta a la pantalla 7
	ld (0f893h),a		;590e
	xor a			;5911
	ld (0f89ch),a		;5912
	jp monta_mapa_ancho		;5915
pinta_el_tablon:		; Dibuja el tablon con sus catorce piezas de sprite
	ld hl,01b28h		;5918   ; 0x1B28: la decima entrada de la tabla de atributos
	ld (0f885h),hl		;591b
	ld a,(0ab35h)		;591e   ; Y del tablon
	ld (0f87fh),a		;5921
	ld a,(0ab34h)		;5924   ; X del tablon
	ld (0f880h),a		;5927
	ld a,00ah		;592a   ; color 10
	ld (0f881h),a		;592c
	ld a,001h		;592f
	call pon_pieza		;5931
	ld a,00dh		;5934
	call pon_pieza		;5936
	call pon_pieza		;5939
	call pon_pieza		;593c
	call pon_pieza		;593f
	ld a,(0f87fh)		;5942   ; 0x28: cinco piezas atras
	sub 028h		;5945
	ld (0f87fh),a		;5947
	ld a,009h		;594a
	call pon_pieza		;594c
	call pon_pieza		;594f
	ld a,00eh		;5952
	call pon_pieza		;5954
	call pon_pieza		;5957
	ld a,001h		;595a
	call pon_pieza		;595c
	ld a,(0f87fh)		;595f
	sub 028h		;5962
	ld (0f87fh),a		;5964
	call ocho_a_la_derecha		;5967
	ld a,(0f8b3h)		;596a   ; 0xF8B3 dice si el tablon lleva remate a un lado o al otro
	cp 001h		;596d
	jp nz,L_59AB		;596f
	ld a,(0f87fh)		;5972   ; ocho pixeles a la derecha
	add a,008h		;5975
	ld (0f87fh),a		;5977
	ld hl,(0f8b1h)		;597a
	ld de,0a5ddh		;597d   ; 0xA5DD: uno de los sprites de mar
	rst 20h			;5980
	jp z,L_59A6		;5981
	ld a,006h		;5984   ; patron 6 si no es ese...
L_5986:
	call pon_pieza		;5986   ; --- tres piezas y 0x18 pixeles atras ---
	call pon_pieza		;5989
	call pon_pieza		;598c
	ld a,(0f87fh)		;598f
	sub 018h		;5992
	ld (0f87fh),a		;5994
	call ocho_a_la_derecha		;5997
	ld a,(0f882h)		;599a   ; el color, del que quedo en 0xF882
	call pon_pieza		;599d
	call pon_pieza		;59a0
	jp pon_pieza		;59a3
L_59A6:
	ld a,00bh		;59a6   ; ...y patron 11 si lo es
	jp L_5986		;59a8
L_59AB:
	ld a,(0f87fh)		;59ab   ; ocho pixeles a la izquierda
	sub 008h		;59ae
	ld (0f87fh),a		;59b0
	ld hl,(0f8b1h)		;59b3
	ld de,0a60dh		;59b6   ; 0xA60D: otro de los sprites de mar
	rst 20h			;59b9
	jp nz,L_59D1		;59ba
	ld a,00bh		;59bd   ; patron 11...
L_59BF:
	call pon_pieza		;59bf   ; --- seis piezas seguidas ---
	call pon_pieza		;59c2
	call pon_pieza		;59c5
	call pon_pieza		;59c8
	call pon_pieza		;59cb
	jp pon_pieza		;59ce
L_59D1:
	ld a,006h		;59d1   ; ...o patron 6
	jp L_59BF		;59d3
baldosa_de:		; Convierte la posicion en pixeles de la ficha BC en baldosa
	ld a,(bc)			;59d6   ; X de la ficha
	add a,004h		;59d7   ; +4 y dividido entre 8: la columna
	srl a		;59d9
	srl a		;59db
	srl a		;59dd
	ld e,a			;59df
	xor a			;59e0
	ld d,a			;59e1
	ld hl,01800h		;59e2   ; 0x1800: la tabla de nombres
	add hl,de			;59e5
	inc bc			;59e6
	ld a,(bc)			;59e7   ; Y de la ficha
	add a,004h		;59e8
	srl a		;59ea
	srl a		;59ec
	srl a		;59ee
	ld de,00020h		;59f0   ; y cada fila son 0x20 baldosas
L_59F3:
	cp 000h		;59f3
	ret z			;59f5
	add hl,de			;59f6
	dec a			;59f7
	jp L_59F3		;59f8

; ----------------------------------------------------------------------
; --- la compra en el almacen ------------------------------
; El almacen de la pantalla 7 tiene los generos puestos en fila
; por el mapa ancho, cada uno en su tramo de columnas, y lo que
; se compra es lo que hay donde este el muñeco. Cada compra
; sube su contador y gasta una unidad de las dieciseis de
; DINERO, que es lo que lleva 0xF8BA.
; ----------------------------------------------------------------------
donde_esta_el_barco:		; Segun la columna, sube el contador del genero que toca
	ld a,(0aafdh)		;59fb   ; la columna del muñeco...
	add a,004h		;59fe
	srl a		;5a00
	srl a		;5a02
	srl a		;5a04
	ld e,a			;5a06
	ld a,(0f89dh)		;5a07   ; ...mas el scroll del mapa ancho
	add a,e			;5a0a
	cp 018h		;5a0b   ; menos de 0x18: AGUA
	jp c,L_5A3C		;5a0d
	cp 01eh		;5a10   ; hasta 0x1D: VINO
	jp c,L_5A4A		;5a12
	cp 023h		;5a15   ; hasta 0x22: COMIDA
	jp c,L_5A58		;5a17
	cp 02ch		;5a1a   ; hasta 0x2B: MADERA
	jp c,L_5A66		;5a1c
	ld hl,0f8b8h		;5a1f   ; y de ahi en adelante, TELA
	call sube_uno		;5a22
	ld hl,0a60dh		;5a25   ; y la TELA usa el sprite de mar de 0xA60D
	ld a,002h		;5a28
L_5A2A:
	ld (0f8b1h),hl		;5a2a
	ld (0f8b3h),a		;5a2d
	ld a,(0f8bah)		;5a30   ; 0xF8BA lleva la cuenta del dinero gastado
	inc a			;5a33
	ld (0f8bah),a		;5a34
	ret			;5a37
sube_uno:		; (HL)++ : una unidad mas del genero que sea
	ld a,(hl)			;5a38
	inc a			;5a39
	ld (hl),a			;5a3a
	ret			;5a3b
L_5A3C:
	ld hl,0f8b4h		;5a3c
	call sube_uno		;5a3f
	ld hl,0a5adh		;5a42
	ld a,001h		;5a45
	jp L_5A2A		;5a47
L_5A4A:
	ld hl,0f8b5h		;5a4a
	call sube_uno		;5a4d
	ld hl,0a5adh		;5a50
	ld a,001h		;5a53
	jp L_5A2A		;5a55
L_5A58:
	ld hl,0f8b6h		;5a58
	call sube_uno		;5a5b
	ld hl,0a5ddh		;5a5e
	ld a,001h		;5a61
	jp L_5A2A		;5a63
L_5A66:
	ld hl,0f8b7h		;5a66
	call sube_uno		;5a69
	ld hl,0a63dh		;5a6c
	ld a,002h		;5a6f
	jp L_5A2A		;5a71
pinta_progreso:		; Marca en el mapa ancho lo que se lleva comprado
	ld a,(0f8bah)		;5a74
	ld e,a			;5a77
	ld a,010h		;5a78   ; dieciseis unidades de dinero en total
	sub e			;5a7a
	sla a		;5a7b
	ld e,a			;5a7d
	xor a			;5a7e
	ld d,a			;5a7f
	ld hl,09807h		;5a80   ; 0x9807: la segunda fila del mapa ancho
	add hl,de			;5a83
	ld a,002h		;5a84
	ld (hl),a			;5a86
	dec hl			;5a87
	ld (hl),a			;5a88
	ld de,00041h		;5a89   ; 0x41: la fila de abajo y una columna
	add hl,de			;5a8c
	ld (hl),a			;5a8d
	dec hl			;5a8e
	ld (hl),a			;5a8f
	ret			;5a90
pinta_franja_inferior:		; Limpia la franja de texto y escribe lo que toque
	ld bc,00140h		;5a91   ; 0x140 bytes: diez filas de baldosa
	ld hl,01638h		;5a94
	xor a			;5a97
	call 00056h		;5a98   ; BIOS FILVRM - Fills VRAM with value
	ld bc,00140h		;5a9b   ; y su color, 0x1F
	ld hl,03638h		;5a9e
	ld a,01fh		;5aa1
	call 00056h		;5aa3   ; BIOS FILVRM - Fills VRAM with value
	ld a,(0f89ch)		;5aa6   ; 0xF89C elige el mensaje
	cp 000h		;5aa9
	jp z,mensaje_puerto		;5aab
	cp 001h		;5aae
	jp z,mensaje_fraile		;5ab0
	cp 002h		;5ab3
	jp z,mensaje_armador		;5ab5
	cp 003h		;5ab8
	jp z,mensaje_cartografo		;5aba
	cp 004h		;5abd
	jp z,mensaje_oficio		;5abf
mensaje_puerto:		; "PUERTO DE PALOS" y "Ano 1492"
	ld hl,0c28ah		;5ac2
	ld a,003h		;5ac5
	call escribe_mensaje		;5ac7
	ld a,006h		;5aca
escribe_segunda_linea:		; La segunda linea del mensaje, mas abajo
	dec hl			;5acc   ; se retrocede un byte, como en la rutina de arriba
	ld (0f87fh),hl		;5acd
	ld hl,01638h		;5ad0   ; 0x1638: el principio de la franja
	ld de,000a0h		;5ad3   ; 0xA0: veinte baldosas mas abajo
	add hl,de			;5ad6
	jp L_5AE1		;5ad7
escribe_mensaje:		; Escribe en la franja de abajo la cadena que apunta HL
	dec hl			;5ada   ; se empieza un byte antes: la rutina de 0x5B7F avanza primero
	ld (0f87fh),hl		;5adb
	ld hl,01638h		;5ade   ; 0x1638: la baldosa donde empieza la franja
L_5AE1:
	ld de,00008h		;5ae1   ; ocho bytes por baldosa
L_5AE4:
	ld (0f883h),a		;5ae4   ; A dice cuantas baldosas se sangra la linea
	cp 000h		;5ae7
	jp z,L_5AF4		;5ae9
	add hl,de			;5aec
	ld a,(0f883h)		;5aed
	dec a			;5af0
	jp L_5AE4		;5af1
L_5AF4:
	ld (0f881h),hl		;5af4
L_5AF7:
	call siguiente_letra		;5af7   ; --- una letra por vuelta ---
	cp 00dh		;5afa   ; el 0x0D termina la linea
	jp z,siguiente_letra		;5afc
	ld hl,01bbfh		;5aff   ; 0x1BBF es CGTABL, la fuente de la ROM
	ld de,00008h		;5b02
L_5B05:
	ld (0f883h),a		;5b05   ; ocho bytes por caracter
	cp 000h		;5b08
	jp z,L_5B15		;5b0a
	add hl,de			;5b0d
	ld a,(0f883h)		;5b0e
	dec a			;5b11
	jp L_5B05		;5b12
L_5B15:
	ld de,(0f881h)		;5b15
	ld bc,00008h		;5b19
	call 0005ch		;5b1c   ; BIOS LDIRVM - Block transfers to VRAM from memory | el patron de la letra, a la tabla de patrones
	ld hl,(0f881h)		;5b1f   ; y la baldosa siguiente
	ld de,00008h		;5b22
	add hl,de			;5b25
	ld (0f881h),hl		;5b26
	jp L_5AF7		;5b29
mensaje_cartografo:		; "Juan de la Cosa" y "Cartografo"
	ld hl,0c2a3h		;5b2c
	ld a,003h		;5b2f
	jp escribe_mensaje		;5b31
mensaje_fraile:		; "Fray Juan Perez"
	ld hl,0c2b3h		;5b34
	ld a,003h		;5b37
	call escribe_mensaje		;5b39
	ld a,005h		;5b3c
	jp escribe_segunda_linea		;5b3e
mensaje_armador:		; "Martin Alonso Pinzon" y "Armador"
	ld hl,0c2ceh		;5b41
	xor a			;5b44
	call escribe_mensaje		;5b45
	ld a,007h		;5b48
	jp escribe_segunda_linea		;5b4a
mensaje_oficio:		; El oficio que toque segun los pasos dados
	ld a,(0f89fh)		;5b4d   ; 0xF89F son los pasos dados
	cp 004h		;5b50   ; cuatro pasos: "Piloto"
	jp z,mensaje_piloto		;5b52
	cp 005h		;5b55   ; cinco: "Cocinero"
	jp z,mensaje_cocinero		;5b57
	cp 006h		;5b5a   ; seis: "Carpintero"
	jp z,mensaje_carpintero		;5b5c
	ld hl,0c306h		;5b5f   ; y de ahi en adelante, "Marinero"
	ld a,005h		;5b62
	jp escribe_mensaje		;5b64
mensaje_piloto:		; "Piloto"
	ld hl,0c2ebh		;5b67
	ld a,006h		;5b6a
	jp escribe_mensaje		;5b6c
mensaje_cocinero:		; "Cocinero"
	ld hl,0c2f2h		;5b6f
	ld a,005h		;5b72
	jp escribe_mensaje		;5b74
mensaje_carpintero:		; "Carpintero"
	ld hl,0c2fbh		;5b77
	ld a,004h		;5b7a
	jp escribe_mensaje		;5b7c
siguiente_letra:		; Avanza el puntero de la cadena y devuelve la letra
	ld hl,(0f87fh)		;5b7f
	inc hl			;5b82
	ld (0f87fh),hl		;5b83
	ld a,(hl)			;5b86
	ret			;5b87
se_acabo:		; El muñeco se cae al agua y la partida vuelve a empezar
	ld a,001h		;5b88
	ld (0f8c2h),a		;5b8a   ; 0xF8C2: la marca de caida, que recorta la figura por abajo
	call espera_2000		;5b8d
	call apunta_al_protagonista		;5b90
	call pinta_al_protagonista		;5b93
	call apunta_al_protagonista		;5b96
	ld a,002h		;5b99   ; cuatro pixeles mas abajo por vuelta
	call campo_del_objeto		;5b9b
	add a,004h		;5b9e
	ld (hl),a			;5ba0
	cp 0a4h		;5ba1   ; hasta la fila 0xA4, ya fuera de la pantalla
	jp nz,se_acabo		;5ba3
	call espera_2000		;5ba6
	call espera_2000		;5ba9
	jp principal		;5bac   ; y a empezar de cero
fin_de_la_travesia:		; El desenlace de la pantalla 7, con su animacion
	ld a,(0f8b9h)		;5baf   ; hace falta haber cumplido el requisito de 0xF8B9...
	cp 000h		;5bb2
	ret z			;5bb4
	ld a,(0f8bah)		;5bb5   ; ...y haber recorrido algun tramo
	cp 000h		;5bb8
	ret z			;5bba
	ld a,003h		;5bbb
	call espera_a_estado		;5bbd
	call borra_sprites		;5bc0
	xor a			;5bc3
	ld (0f87fh),a		;5bc4
	ld a,018h		;5bc7
	ld (0f880h),a		;5bc9
	ld hl,01ae0h		;5bcc   ; 0x1AE0: la ultima fila de la tabla de nombres
	ld (0f881h),hl		;5bcf
	ld a,018h		;5bd2
	ld (0f883h),a		;5bd4
	ld a,020h		;5bd7
	ld (0f884h),a		;5bd9
L_5BDC:
	call espera_500		;5bdc   ; --- va tapando la pantalla en espiral ---
	ld hl,(0f881h)		;5bdf
	ld a,019h		;5be2   ; 0x19: la baldosa que lo tapa todo
	call 0004dh		;5be4   ; BIOS WRTVRM - Writes data in VRAM
	ld a,(0f880h)		;5be7
	dec a			;5bea
	ld (0f880h),a		;5beb
	cp 000h		;5bee
	jp z,L_5C23		;5bf0
L_5BF3:
	ld hl,(0f881h)		;5bf3   ; --- elige por donde sigue tapando ---
	ld a,(0f87fh)		;5bf6
	cp 000h		;5bf9
	jp z,L_5C0F		;5bfb
	cp 001h		;5bfe
	jp z,L_5C18		;5c00
	cp 002h		;5c03
	jp z,L_5C1C		;5c05
	dec hl			;5c08
L_5C09:
	ld (0f881h),hl		;5c09
	jp L_5BDC		;5c0c
L_5C0F:
	ld de,00020h		;5c0f   ; arriba
	xor a			;5c12
	sbc hl,de		;5c13
	jp L_5C09		;5c15
L_5C18:
	inc hl			;5c18   ; a la derecha
	jp L_5C09		;5c19
L_5C1C:
	ld de,00020h		;5c1c   ; abajo
	add hl,de			;5c1f
	jp L_5C09		;5c20
L_5C23:
	ld a,(0f87fh)		;5c23   ; y cuatro direcciones que se van turnando
	inc a			;5c26
	ld (0f87fh),a		;5c27
	cp 004h		;5c2a
	jp nz,L_5C33		;5c2c
	xor a			;5c2f
	ld (0f87fh),a		;5c30
L_5C33:
	cp 000h		;5c33   ; en las direcciones pares se gasta una fila...
	jp z,L_5C4F		;5c35
	cp 002h		;5c38
	jp z,L_5C4F		;5c3a
	ld a,(0f884h)		;5c3d   ; ...y en las impares, una columna
	dec a			;5c40
	ld (0f884h),a		;5c41
L_5C44:
	ld (0f880h),a		;5c44
	cp 000h		;5c47
	jp z,fin_de_la_primera_parte		;5c49
	jp L_5BF3		;5c4c
L_5C4F:
	ld a,(0f883h)		;5c4f
	dec a			;5c52
	ld (0f883h),a		;5c53
	jp L_5C44		;5c56
fin_de_la_primera_parte:		; Monta la pantalla de espera y va a por la segunda
	ld hl,0c310h		;5c59   ; la tabla de nombres de la pantalla que se ve mientras carga
	ld bc,00300h		;5c5c   ; 0x300 bytes: 32 por 24
	ld de,01800h		;5c5f
	call 0005ch		;5c62   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld hl,0bdb7h		;5c65   ; sus patrones: 0x198 bytes a la baldosa 0x5B
	ld bc,00198h		;5c68
	ld de,002d8h		;5c6b
	call vuelca_comprimido		;5c6e
	ld hl,0bf82h		;5c71   ; y 0x48 mas a la baldosa 0x8E
	ld bc,00048h		;5c74
	ld de,00470h		;5c77
	call vuelca_con_color		;5c7a
	ld a,004h		;5c7d   ; el protagonista pasa al estado 4
	ld (0f89ch),a		;5c7f
	call apunta_al_protagonista		;5c82
	ld a,001h		;5c85   ; y se coloca en la columna 0x90, fila 0x78
	call campo_del_objeto		;5c87
	ld a,090h		;5c8a
	ld (hl),a			;5c8c
	ld a,078h		;5c8d
	inc hl			;5c8f
	ld (hl),a			;5c90
	ld a,003h		;5c91   ; con el estado 3 y sin fotograma
	inc hl			;5c93
	ld (hl),a			;5c94
	inc hl			;5c95
	xor a			;5c96
	ld (hl),a			;5c97
	call pinta_al_protagonista		;5c98   ; se dibuja por ultima vez
	call pinta_resumen		;5c9b   ; y se pintan las cifras del resumen
	ld hl,0f8b4h		;5c9e   ; guarda en 0xD6D9-0xD6DE lo conseguido: la segunda parte lo lee en 0x4037
	ld a,(hl)			;5ca1
	ld (0d6d9h),a		;5ca2   ; 0xD6D9 <- 0xF8B4, el AGUA
	inc hl			;5ca5
	ld a,(hl)			;5ca6
	ld (0d6dah),a		;5ca7   ; 0xD6DA <- 0xF8B5, el VINO
	inc hl			;5caa
	ld a,(hl)			;5cab
	ld (0d6ddh),a		;5cac   ; 0xD6DD, no 0xD6DB: la COMIDA se cruza con la MADERA
	inc hl			;5caf
	ld a,(hl)			;5cb0
	ld (0d6dbh),a		;5cb1   ; 0xD6DB <- 0xF8B7, la MADERA
	inc hl			;5cb4
	ld a,(hl)			;5cb5
	ld (0d6dch),a		;5cb6   ; 0xD6DC <- 0xF8B8, la TELA
	inc hl			;5cb9
	ld a,(hl)			;5cba
	ld (0d6deh),a		;5cbb   ; 0xD6DE <- 0xF8B9, los MARINEROS: la tripulacion de la travesia
	xor a			;5cbe
	ld (0d6d8h),a		;5cbf   ; el DINERO (0xF8BA) no se pasa: se queda en esta primera parte
	ld hl,(0d300h)		;5cc2   ; (0xD300) vale 0xD369: el bucle del cargador que lee un bloque de cinta
	push hl			;5cc5   ; se salta metiendolo en la pila
	ret			;5cc6
cuelgue:		; Si la cinta no arranca, aqui se queda
	jp cuelgue		;5cc7
espera_500:		; Cuenta hasta 500 en 0xF891
	ld hl,(0f891h)		;5cca   ; 0xF891 es el contador de espera
	inc hl			;5ccd
	ld (0f891h),hl		;5cce
	ld de,001f4h		;5cd1   ; 0x1F4 = 500 vueltas
	rst 20h			;5cd4
	jp nz,espera_500		;5cd5
	ld hl,00000h		;5cd8   ; y al llegar se pone a cero para la proxima
	ld (0f891h),hl		;5cdb
	ret			;5cde

; ----------------------------------------------------------------------
; ==========================================================
; EL RESUMEN DE LO CONSEGUIDO, Y QUE ES CADA CONTADOR
; ==========================================================
; Dibujada con tools/dibuja.py, esta pantalla sale con siete
; rotulos y siete cifras de dos digitos. La correspondencia
; entre cada cifra y su rotulo NO se ha supuesto: el bucle de
; aqui abajo pinta las catorce cifras en baldosas seguidas, de
; la 188 a la 201, y basta buscar esas baldosas en la tabla de
; nombres de 0xC310 para ver bajo que rotulo cae cada una.
; Sale esto, y no el orden que uno esperaria:
;
; 0xF8B4  AGUA      (baldosas 188-189, fila 13 columna 9)
; 0xF8B5  VINO      (190-191, fila 18 columna 9)
; 0xF8B6  COMIDA    (192-193, fila 8 columna 9)
; 0xF8B7  MADERA    (194-195, fila 5 columna 22)
; 0xF8B8  TELA      (196-197, fila 12 columna 22)
; 0xF8B9  MARINERO  (198-199, fila 17 columna 22)
; 0xF8BA  DINERO    (200-201, fila 4 columna 9)
;
; Las cinco primeras son las mercancias que se compran en el
; almacen de la pantalla 7 -y por eso el rotulo de esa pantalla
; dice AGUA VINO COM...-: la rutina de 0x59FB mira por que
; tramo del mapa ancho va el muñeco y sube el contador que
; toca. El DINERO es el unico que se ensena RESTADO DE 16, o
; sea lo que queda despues de comprar, y el unico que NO se le
; pasa a la segunda parte. MARINERO sale del marcador de
; reclutamiento menos dos (0x53AE).
; ----------------------------------------------------------------------
pinta_resumen:		; El dibujo y las cifras de la pantalla de espera
	ld hl,0c618h		;5cdf   ; 0x150 bytes de dibujo a la baldosa 0xCA
	ld de,00650h		;5ce2
	ld bc,00150h		;5ce5
	call vuelca_comprimido_en		;5ce8
	ld hl,025e0h		;5ceb   ; 0x25E0: la tabla de colores del segundo tercio
	ld (0f881h),hl		;5cee
	ld hl,00008h		;5cf1
	ld (0f883h),hl		;5cf4
L_5CF7:
	ld hl,(0f881h)		;5cf7   ; --- pinta de color 0x1F un tramo de 0x70 bytes por tercio ---
	ld bc,00070h		;5cfa
	ld a,01fh		;5cfd
	call 00056h		;5cff   ; BIOS FILVRM - Fills VRAM with value
	call baja_un_tercio		;5d02   ; y baja un tercio
	ld de,03de0h		;5d05   ; hasta 0x3DE0, el final de la tabla de colores
	rst 20h			;5d08
	jp nz,L_5CF7		;5d09
	ld hl,0f8b3h		;5d0c   ; los siete contadores se leen a partir de 0xF8B3...
	ld (0f885h),hl		;5d0f
	ld hl,005e0h		;5d12   ; ...y se pintan a partir de la baldosa 0xBC
	ld (0f881h),hl		;5d15
L_5D18:
	call siguiente_contador		;5d18   ; --- una cifra por vuelta ---
	ld hl,01d3fh		;5d1b   ; las cifras de 0 a 9 estan en la baldosa 0x27A...
	cp 00ah		;5d1e
	jp c,L_5D28		;5d20
	sub 00ah		;5d23
	ld hl,01d47h		;5d25   ; ...y las de 10 en adelante, en la 0x28A
L_5D28:
	ld (0f887h),a		;5d28   ; la parte que sobra de la decena
	ld (0f87fh),hl		;5d2b   ; y donde se pinta
	call pinta_cifra		;5d2e   ; la primera cifra
	ld a,(0f887h)		;5d31
	ld hl,01d3fh		;5d34
	ld de,00008h		;5d37
L_5D3A:
	cp 000h		;5d3a   ; --- salta hasta la baldosa de la unidad ---
	jp z,L_5D4D		;5d3c
	add hl,de			;5d3f
	ld (0f87fh),hl		;5d40
	ld a,(0f887h)		;5d43
	dec a			;5d46
	ld (0f887h),a		;5d47
	jp L_5D3A		;5d4a
L_5D4D:
	call pinta_cifra		;5d4d   ; y la segunda cifra
	ld hl,(0f885h)		;5d50   ; hasta llegar a 0xF8BA, el ultimo contador
	ld de,0f8bah		;5d53
	rst 20h			;5d56
	jp nz,L_5D18		;5d57
	ret			;5d5a
pinta_cifra:		; Sube una cifra a los tres tercios y retrocede
	call tres_tercios		;5d5b   ; la misma cifra en los tres tercios
	ld de,00ff8h		;5d5e   ; 0xFF8: vuelve al tercio de arriba, una baldosa mas alla
	ld hl,(0f881h)		;5d61
	xor a			;5d64
	sbc hl,de		;5d65
	ld (0f881h),hl		;5d67
	ret			;5d6a
siguiente_contador:		; Devuelve el valor del contador siguiente
	ld hl,(0f885h)		;5d6b   ; avanza al contador de al lado
	inc hl			;5d6e
	ld (0f885h),hl		;5d6f
	ld de,0f8bah		;5d72   ; el septimo y ultimo es 0xF8BA, el DINERO...
	rst 20h			;5d75
	jp nz,L_5D7F		;5d76
	ld a,(hl)			;5d79
	ld e,a			;5d7a
	ld a,010h		;5d7b   ; ...y ese se ensena restado de 16: lo que queda tras comprar
	sub e			;5d7d
	ret			;5d7e
L_5D7F:
	ld a,(hl)			;5d7f
	ret			;5d80
anima_la_bandera:		; En la pantalla 2, la bandera del mastil ondeando
	ld a,(0f893h)		;5d81
	cp 002h		;5d84   ; solo en la pantalla 2
	ret nz			;5d86
	ld a,(0f8c1h)		;5d87   ; 0xF8C1: una vuelta de cada diez
	inc a			;5d8a
	ld (0f8c1h),a		;5d8b
	cp 00ah		;5d8e
	ret nz			;5d90
	xor a			;5d91
	ld (0f8c1h),a		;5d92
	ld a,(0f8bbh)		;5d95   ; 0xF8BB: el fotograma, de 0 a 2
	inc a			;5d98
	ld (0f8bbh),a		;5d99
	cp 001h		;5d9c
	jp z,L_5DAD		;5d9e
	cp 003h		;5da1
	jp nz,L_5DBD		;5da3
	xor a			;5da6
	ld (0f8bbh),a		;5da7
	jp L_5DBD		;5daa
L_5DAD:
	ld a,(0f8bch)		;5dad   ; 0xF8BC: el segundo contador, tambien de 0 a 2
	inc a			;5db0
	ld (0f8bch),a		;5db1
	cp 003h		;5db4
	jp nz,L_5DBD		;5db6
	xor a			;5db9
	ld (0f8bch),a		;5dba
L_5DBD:
	ld hl,01872h		;5dbd   ; 0x1872: la baldosa de la bandera
	ld de,00005h		;5dc0   ; cinco baldosas de separacion entre fotogramas
	call avanza_bc_veces		;5dc3
	ld a,(0f8bbh)		;5dc6
	ld e,a			;5dc9
	ld a,0c9h		;5dca   ; la baldosa de la bandera se cuenta hacia atras desde 0xC9
	sub e			;5dcc
	call 0004dh		;5dcd   ; BIOS WRTVRM - Writes data in VRAM
	ld a,(0f8bch)		;5dd0
	inc a			;5dd3
	cp 003h		;5dd4
	jp nz,L_5DDA		;5dd6
	xor a			;5dd9
L_5DDA:
	ld hl,01874h		;5dda   ; la segunda mitad de la bandera, en 0x1874
	ld de,00005h		;5ddd
	call avanza_a_veces		;5de0
	ld a,(0f8bbh)		;5de3
	ld e,a			;5de6
	ld a,0cch		;5de7   ; y esa hacia atras desde 0xCC
	sub e			;5de9
	jp 0004dh		;5dea   ; BIOS WRTVRM - Writes data in VRAM
avanza_bc_veces:		; HL += DE, repetido 0xF8BC veces
	ld a,(0f8bch)		;5ded
avanza_a_veces:		; HL += DE, repetido A veces
	ld (0f883h),a		;5df0   ; el numero de pasos se guarda en 0xF883
	cp 000h		;5df3   ; con cero pasos, HL se queda como esta
	ret z			;5df5
	add hl,de			;5df6   ; un paso
	ld a,(0f883h)		;5df7
	dec a			;5dfa
	jp avanza_a_veces		;5dfb
anima_el_pajaro:		; En la pantalla 2, el ave que cruza la escena
	ld a,(0f893h)		;5dfe
	cp 002h		;5e01   ; solo en la pantalla 2
	ret nz			;5e03
	ld a,(0f890h)		;5e04   ; la primera vez hay que pintar el fondo
	cp 000h		;5e07
	jp nz,mueve_el_pajaro		;5e09
	inc a			;5e0c
	ld (0f890h),a		;5e0d
	ld hl,0c792h		;5e10   ; 0x60 bytes de dibujo a la baldosa 0xC7
	ld de,00638h		;5e13
	ld bc,00060h		;5e16
	call vuelca_con_color		;5e19
L_5E1C:
	ld a,(0f8bfh)		;5e1c   ; 0xF8BF es la columna por la que va
	ld e,a			;5e1f
	xor a			;5e20
	ld d,a			;5e21
	ld hl,01955h		;5e22   ; 0x1955: la fila por la que cruza
	add hl,de			;5e25
	ld a,0cfh		;5e26   ; baldosas 0xCF, 0xD0 y 0xD1 o 0xD2
	call 0004dh		;5e28   ; BIOS WRTVRM - Writes data in VRAM
	ld de,00020h		;5e2b
	add hl,de			;5e2e
	ld a,0d0h		;5e2f
	call 0004dh		;5e31   ; BIOS WRTVRM - Writes data in VRAM
	ld de,00020h		;5e34
	add hl,de			;5e37
	ld a,(0f8beh)		;5e38   ; 0xF8BE alterna las dos baldosas de la cola: el aleteo
	inc a			;5e3b
	ld (0f8beh),a		;5e3c
	cp 002h		;5e3f
	jp nz,L_5E48		;5e41
	xor a			;5e44
	ld (0f8beh),a		;5e45
L_5E48:
	add a,0d1h		;5e48
	jp 0004dh		;5e4a   ; BIOS WRTVRM - Writes data in VRAM
mueve_el_pajaro:		; Cada veinte vueltas, el ave cambia de columna
	ld a,(0f8bdh)		;5e4d   ; 0xF8BD: el contador de vuelo
	inc a			;5e50
	ld (0f8bdh),a		;5e51
	cp 014h		;5e54   ; veinte vueltas por paso
	jp nz,L_5E1C		;5e56
	xor a			;5e59
	ld (0f8bdh),a		;5e5a
	ld a,(0f8c0h)		;5e5d   ; 0xF8C0 dice si va o viene
	cp 000h		;5e60
	jp z,L_5E7A		;5e62
	ld a,(0f8bfh)		;5e65
	cp 000h		;5e68
	jp z,cambia_el_sentido		;5e6a
	call borra_el_pajaro		;5e6d
	ld a,(0f8bfh)		;5e70
	dec a			;5e73
L_5E74:
	ld (0f8bfh),a		;5e74
	jp L_5E1C		;5e77
L_5E7A:
	ld a,(0f8bfh)		;5e7a   ; ida: hasta la columna 3
	cp 003h		;5e7d
	jp z,cambia_el_sentido		;5e7f
	call borra_el_pajaro		;5e82
	ld a,(0f8bfh)		;5e85
	inc a			;5e88
	jp L_5E74		;5e89
borra_el_pajaro:		; Deja la baldosa 0x19 donde estaba el ave
	ld e,a			;5e8c
	xor a			;5e8d
	ld d,a			;5e8e
	ld hl,01955h		;5e8f   ; 0x1955: la fila del ave
	add hl,de			;5e92
	ld a,019h		;5e93   ; 0x19 es la baldosa vacia
	call 0004dh		;5e95   ; BIOS WRTVRM - Writes data in VRAM
	call baja_una_fila_pajaro		;5e98
	call 0004dh		;5e9b   ; BIOS WRTVRM - Writes data in VRAM
	call baja_una_fila_pajaro		;5e9e
	ld a,060h		;5ea1   ; 0x60: el remate de abajo
	jp 0004dh		;5ea3   ; BIOS WRTVRM - Writes data in VRAM
cambia_el_sentido:		; 0xF8C0 alterna entre 0 y 1
	ld a,(0f8c0h)		;5ea6   ; 0 = el ave va; 1 = vuelve
	inc a			;5ea9
	ld (0f8c0h),a		;5eaa
	cp 002h		;5ead   ; al llegar a 2 se da la vuelta
	ret nz			;5eaf
	xor a			;5eb0   ; y se pone a cero
	ld (0f8c0h),a		;5eb1
	ret			;5eb4
baja_una_fila_pajaro:		; Una fila mas abajo y la baldosa vacia
	ld de,00020h		;5eb5
	add hl,de			;5eb8
	ld a,019h		;5eb9
	ret			;5ebb
musica_de_la_pantalla:		; Al cambiar de pantalla, cambia lo que suena
	ld a,(0f8c6h)		;5ebc   ; 0xF8C6 recuerda para que pantalla es la musica de ahora
	ld e,a			;5ebf
	ld a,(0f893h)		;5ec0   ; si la pantalla no ha cambiado, no hay nada que hacer
	cp e			;5ec3
	jp z,sigue_la_musica		;5ec4
	ld (0f8c6h),a		;5ec7
	ld a,0c9h		;5eca   ; 0xC9 en H.KEYI: un RET, con lo que la musica se para en seco
	ld (0fd9fh),a		;5ecc
	call 00090h		;5ecf   ; BIOS GICINI - Initialises PSG and sets initial value for the PLAY statement | GICINI deja el PSG mudo
	ld a,(0f8c6h)		;5ed2   ; pantalla 0: el zumbido de fondo
	and a			;5ed5
	jp z,zumbido		;5ed6
	cp 006h		;5ed9   ; pantalla 6: el mismo
	jp z,zumbido		;5edb
	cp 002h		;5ede   ; pantalla 2: la melodia de 0xCB95
	ret nz			;5ee0
L_5EE1:
	ld hl,0cb95h		;5ee1
	jp L_4361		;5ee4
sigue_la_musica:		; La pantalla no ha cambiado: se mira si toca repetir
	ld a,(0f8c6h)		;5ee7
	cp 002h		;5eea   ; en la pantalla 2, cuando la melodia acaba se repite
	jp nz,L_5EF6		;5eec
	call melodia_terminada		;5eef
	ret nz			;5ef2
	jp L_5EE1		;5ef3
L_5EF6:
	ld a,(0f8c6h)		;5ef6   ; en la pantalla 3, el sonido del reloj de arena
	cp 003h		;5ef9
	ret nz			;5efb
	ld a,(0f8a1h)		;5efc
	cp 064h		;5eff   ; a los cien tics del reloj, un aviso
	jp z,aviso_del_reloj		;5f01
	jp c,00090h		;5f04   ; BIOS GICINI - Initialises PSG and sets initial value for the PLAY statement | y por debajo de cien, silencio
	ret			;5f07
aviso_del_reloj:		; El pitido de aviso del reloj de arena
	ld a,0ffh		;5f08   ; registros 0 y 1: el tono grueso y el fino
	ld e,064h		;5f0a
	call siguiente_registro		;5f0c
	ld e,014h		;5f0f
	call siguiente_registro		;5f11
	ld e,064h		;5f14
	call siguiente_registro		;5f16
	ld e,032h		;5f19
	call siguiente_registro		;5f1b
	ld a,006h		;5f1e   ; registros 6 a 8: ruido y volumen
	ld e,03ch		;5f20
	call siguiente_registro		;5f22
	ld e,010h		;5f25
	call siguiente_registro		;5f27
	ld e,010h		;5f2a
	call siguiente_registro		;5f2c
	ld a,00ah		;5f2f   ; registros 10 a 12: el envolvente
	ld e,000h		;5f31
	call siguiente_registro		;5f33
	ld e,032h		;5f36
	call siguiente_registro		;5f38
	ld e,008h		;5f3b
siguiente_registro:		; Escribe el registro A y pasa al siguiente
	inc a			;5f3d
	jp 00093h		;5f3e   ; BIOS WRTPSG - Writes data to PSG-register
zumbido:		; El zumbido de fondo de las pantallas 0 y 6
	ld a,006h		;5f41   ; registros 6, 7 y 8: ruido, mezcla y volumen
	ld e,014h		;5f43
	call 00093h		;5f45   ; BIOS WRTPSG - Writes data to PSG-register
	inc a			;5f48
	ld e,037h		;5f49
	call 00093h		;5f4b   ; BIOS WRTPSG - Writes data to PSG-register
	inc a			;5f4e
	ld e,010h		;5f4f
	call 00093h		;5f51   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00ch		;5f54   ; registros 12 y 13: el envolvente lento
	ld e,050h		;5f56
	call 00093h		;5f58   ; BIOS WRTPSG - Writes data to PSG-register
	inc a			;5f5b
	ld e,00eh		;5f5c
	jp 00093h		;5f5e   ; BIOS WRTPSG - Writes data to PSG-register
lee_mando:		; Deja en 0xF894 la direccion del mando o del cursor
	ld a,007h		;5f61   ; el registro 7 del PSG, por si hay que mirar el puerto de mando
	call 00096h		;5f63   ; BIOS RDPSG - Reads value from PSG-register
	cp 037h		;5f66
	jp z,L_5F6B		;5f68
L_5F6B:
	xor a			;5f6b   ; primero el cursor del teclado...
	call 000d5h		;5f6c   ; BIOS GTSTCK - Returns the joystick status
	and a			;5f6f
	jp nz,L_5F78		;5f70
	ld a,001h		;5f73   ; ...y si no hay nada, el mando del puerto 1
	call 000d5h		;5f75   ; BIOS GTSTCK - Returns the joystick status
L_5F78:
	ld (0f894h),a		;5f78
	ret			;5f7b
L_5F7C:
	ld a,(0f894h)		;5f7c
	ret			;5f7f
lee_gatillo:		; Deja en 0xF8C4 el gatillo o la barra
	ld a,007h		;5f80
	call 00096h		;5f82   ; BIOS RDPSG - Reads value from PSG-register
	cp 037h		;5f85
	jp z,L_5F8A		;5f87
L_5F8A:
	xor a			;5f8a   ; primero la barra espaciadora...
	call 000d8h		;5f8b   ; BIOS GTTRIG - Returns current trigger status
	and a			;5f8e
	jp nz,L_5F97		;5f8f
	ld a,001h		;5f92   ; ...y si no, el boton del mando
	call 000d8h		;5f94   ; BIOS GTTRIG - Returns current trigger status
L_5F97:
	ld (0f8c4h),a		;5f97
	ret			;5f9a
L_5F9B:
	ld a,(0f8c4h)		;5f9b
	ret			;5f9e

; ----------------------------------------------------------------------
; DATOS restos_de_montaje: 0x59 bytes que no ejecuta nadie. Son copia EXACTA
;   de 0x5F1F-0x5F77, ochenta bytes mas arriba (comprobado byte a byte:
;   0x5F9F-0x5FE0 contra 0x5F1F-0x5F60, y 0x5FE1-0x5FF7 contra 0x5F61-0x5F77).
;   La copia se corta a media instruccion, en el 0x32 de un `ld (nn),a`. El
;   mismo artefacto sale al final del cargador y al final de la segunda parte.
;   0x5f9f..0x5ff8  (89 bytes)
DATA_restos_de_montaje:
	defb 006h,01eh,03ch,0cdh,03dh,05fh,01eh,010h	; 5f9f  ..<.=_..
	defb 0cdh,03dh,05fh,01eh,010h,0cdh,03dh,05fh	; 5fa7  .=_...=_
	defb 03eh,00ah,01eh,000h,0cdh,03dh,05fh,01eh	; 5faf  >....=_.
	defb 032h,0cdh,03dh,05fh,01eh,008h,03ch,0c3h	; 5fb7  2.=_..<.
	defb 093h,000h,03eh,006h,01eh,014h,0cdh,093h	; 5fbf  ..>.....
	defb 000h,03ch,01eh,037h,0cdh,093h,000h,03ch	; 5fc7  .<.7...<
	defb 01eh,010h,0cdh,093h,000h,03eh,00ch,01eh	; 5fcf  .....>..
	defb 050h,0cdh,093h,000h,03ch,01eh,00eh,0c3h	; 5fd7  P...<...
	defb 093h,000h,03eh,007h,0cdh,096h,000h,0feh	; 5fdf  ..>.....
	defb 037h,0cah,06bh,05fh,0afh,0cdh,0d5h,000h	; 5fe7  7.k_....
	defb 0a7h,0c2h,078h,05fh,03eh,001h,0cdh,0d5h	; 5fef  ..x_>...
	defb 000h	; 5ff7

; ----------------------------------------------------------------------
; DATOS relleno_de_bloque: Los 1032 bytes que sobran del trozo de 0x2400.
;   Desde 0x5FF9 son el patron de ocho bytes 00 FF FF FF FF 00 00 00 repetido
;   129 veces sin una sola excepcion (comprobado); dibujado es una barra
;   horizontal. Ninguna instruccion del programa los lee. Es la unica de las
;   tres colas de bloque de la cinta que esta VACIA de verdad: la
;   autocorrelacion da el 100 % en todos los multiplos de 8, o sea que no
;   lleva ni un bit de informacion. Aun asi comparte el esqueleto de las otras
;   dos: leida desde 0x5FFA los registros de ocho son cuatro bytes acabados en
;   F y cuatro acabados en 0, la misma fase (resto 2 al dividir por 8) que
;   0x5C7A y 0xCCDA de la segunda parte.
;   0x5ff8..0x6400  (1032 bytes)
DATA_relleno_de_bloque:
	defb 032h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 5ff8  2.......
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6000  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6008  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6010  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6018  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6020  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6028  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6030  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6038  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6040  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6048  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6050  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6058  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6060  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6068  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6070  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6078  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6080  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6088  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6090  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6098  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 60a0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 60a8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 60b0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 60b8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 60c0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 60c8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 60d0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 60d8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 60e0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 60e8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 60f0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 60f8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6100  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6108  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6110  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6118  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6120  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6128  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6130  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6138  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6140  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6148  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6150  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6158  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6160  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6168  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6170  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6178  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6180  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6188  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6190  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6198  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 61a0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 61a8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 61b0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 61b8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 61c0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 61c8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 61d0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 61d8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 61e0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 61e8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 61f0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 61f8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6200  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6208  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6210  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6218  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6220  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6228  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6230  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6238  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6240  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6248  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6250  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6258  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6260  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6268  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6270  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6278  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6280  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6288  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6290  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6298  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 62a0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 62a8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 62b0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 62b8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 62c0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 62c8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 62d0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 62d8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 62e0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 62e8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 62f0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 62f8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6300  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6308  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6310  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6318  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6320  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6328  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6330  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6338  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6340  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6348  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6350  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6358  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6360  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6368  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6370  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6378  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6380  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6388  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6390  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 6398  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 63a0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 63a8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 63b0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 63b8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 63c0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 63c8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 63d0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 63d8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 63e0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 63e8  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 63f0  ........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h	; 63f8  ........
