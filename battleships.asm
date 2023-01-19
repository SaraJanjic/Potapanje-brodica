// crvena 001 (+) - kursor
// zelena 010 (O) - pogodjeno
// plava 100 (x) - promaseno

// makro za restart vrednosti registra
#define ZERO(R) sub R, R, R

.data
8 				// sirina rgb_matrix-a (cesto koriscen broj u kodu)
0				// frame_cnt
60				// max_frames - govori koliko frejmova treba da se ceka, pre nego sto se ucita input (za simulaciju =1, za plocu 60+)
0xACAB			// konstanta koja se koristi kod random number generatora
15				// temp promenljiva koja se koristi za cuvanje broja polja brodova (! ovo rucno podesavamo)

// Vazne adrese
0x100			// pocetak rgb_matrix adrese
0x140			// adresa od frame_sync-a
0x200			// adresa od pb_dec

// Koordinate kursora
4, 4
// Koordinate brodova i promasenih polja (tip polja, x i y koordinata)
// Tipovi polja: 0 - skriven brod; 1 - pogodjen brod; 2 - promaseno polje
-1				// oznaka za kraj koordinata

.text
/*
	Spisak registara i njihove najcesce namene:
	R0 - register za adrese
	R1 - najcesce temp x koordinate
	R2 - najcesce temp y koordinate
	R3 - boja
	R4 - pb_dec
	R5 - rgb_matrix
	R6 - frame_sync
	R7 - temp registar za svasta
*/
generate_seed:
	ld R0, R0
	dec R0, R0		// R0 pokazuje na pb_dec
	ld R4, R0
	inc R4, R4
	inc R4, R4		// R4 sada pokazuje na memoriju gde se cuva vrednost srednjeg tastera
	ZERO(R7)
	st R7, R4		// restartujemo vrednost srednjeg tastera, pre nego sto udjemo u petlju

	inc R0, R0
	inc R0, R0
	inc R0, R0		// R0 sada pokazuje na pocetak adresnog prostora gde se upisuju polja

	seed_loop:
		ld R7, R4			// ucitamo u R7 da bismo proverili dal je centralni taster pritisnut
		jmpnz generate_ships
		inc R1, R1			// povecamo R1 (u njemu cuvamo seed)
		jmp seed_loop


generate_ships:
	//ZERO(R1)			//! za debagovanje (vratimo seed na 0)

	ZERO(R3)
	inc R3, R3
	inc R3, R3
	inc R3, R3
	ld R3, R3			// u R3 cuvamo rng konstantu

	ZERO(R7)
	ld R2, R7
	dec R2, R2			// R2 sada sadrzi bitove 111 (to ce nam biti maska)

	ZERO(R4)
	inc R4, R4
	shl R4, R4
	shl R4, R4
	ld R4, R4			// R4 sadrzi broj brodova koliko zelimo da izgenerisemo

	generate_ships_loop:
		and R4, R4, R4
		jmpz start

		ZERO(R7)
		//inc R7, R7		//! za debagovanje (provera generisanih brodova)
		st R7, R0			// upisemo 0 za brod (pocetno stanje kao skriven)

		inc R0, R0
		and R7, R1, R2
		st R7, R0			// upisemo x koordinatu broda

		inc R0, R0
		mov R7, R1
		shr R7, R7
		shr R7, R7
		shr R7, R7			// uzmemo naredna 3 bita iz seed-a
		and R7, R7, R2
		st R7, R0			// upisemo y koordinatu broda

		inc R0, R0
		ZERO(R7)
		dec R7, R7
		st R7, R0			// dodamo -1 na kraj

		add R1, R1, R3		// dodamo konstantu na seed
		dec R4, R4			// smanjimo broj brodova

		jmp generate_ships_loop


start:
	ZERO(R0)
	ld R0, R0
	dec R0, R0
	dec R0, R0
	dec R0, R0

	ld R5, R0	// R5 sadrzi rgb_matrix
	inc R0, R0
	ld R6, R0	// R6 sadrzi frame_sync
	inc R0, R0
	ld R4, R0	// R4 sadrzi pb_dec
	// Vrednost R4, R5 i R6 necemo menjati

check_game_end:
	ZERO(R0)
	inc R0, R0
	shl R0, R0
	shl R0, R0	// R0 sada pokazuje na promenljivu koja broji koliko brodova je ostalo u igri
	ld R7, R0
	jmpz end	// ako je u R7 broj 0, znaci da je kraj igre

frame_sync_rising_edge:
	frame_sync_wait_0:			// rutine za osvezavanje rgb_matrix-a
		ld R7, R6
		jmpnz frame_sync_wait_0
	frame_sync_wait_1:
		ld R7, R6
		jmpz frame_sync_wait_1

restart_addr_pointer:
	ZERO(R0)						// Restart resgistra R0 koji cuva trenutnu adresu citanja
	ZERO(R7)
	ld R0, R0
	inc R0, R0
	inc R0, R0						// R0 sada pokazuje na prvu koordinatu polja


draw_fields:
	ZERO(R3)
	inc R3, R3
	shl R3, R3					// R3 sadrzi ZELENU boju (boja broda)

	ld R7, R0					// u R7 stavljamo tip polja
	jmps draw_cursor			// ako je vrednost -1, tada skacemo na deo gde crtamo kursor

	and R7, R7, R7				// ako se upali z flag znaci da je brod skriven
	jmpz move_to_next_point_1	// pa ga ne crtamo

	ld R7, R0
	shr R7, R7
	and R7, R7, R7
	jmpz draw					// ako se upali z flag znaci da crtamo brod

	shl R3, R3					// R3 sadrzi PLAVU boju (boja promasenog polja)

	draw:

	ZERO(R7)
	ld R7, R7					// R7 sadrzi broj 8 (tolika je sirina rgb_matrix-a)

	inc R0, R0
	ld R1, R0					// ucitavamo x koordinatu (u njemu cemo cuvati pomeraj)
	inc R0, R0
	ld R2, R0					// ucitavamo y koordinatu

	dec R0, R0
	dec R0, R0

	loop_1:
		and R2, R2, R2
		jmpz continue_1
		add R1, R1, R7			// pomeramo se vrstu po vrstu
		dec R2, R2				// onoliko puta koliko je vrednost y koordinate (tj. R2 registra)
		jmp loop_1
	continue_1:

	add R1, R1, R5				// dodamo u R1 adresu od rgb_matrix
	st R3, R1					// crtamo na rgb_matrix na poziciji (x,y)

	move_to_next_point_1:
	inc R0, R0
	inc R0, R0
	inc R0, R0					// pomeramo R0 na sledecu (x, y) koordinatu

	jmp draw_fields


draw_cursor:
	ZERO(R0)
	ld R0, R0					// R0 pokazuje na koordinate kursora

	ZERO(R3)
	inc R3, R3					// R3 sadrzi CRVENU boju (boja kursora)

	ZERO(R7)
	ld R7, R7					// R7 sadrzi broj 8 (tolika je sirina rgb_matrix-a)

	ld R1, R0					// ucitavamo x i y koordinatu kursora u registre R1 i R2
	inc R0, R0
	ld R2, R0
	dec R0, R0

	loop_2:
		and R2, R2, R2
		jmpz continue_2
		add R1, R1, R7			// pomeramo se vrstu po vrstu
		dec R2, R2				// onoliko puta koliko je vrednost y koordinate (tj. R2 registra)
		jmp loop_2
	continue_2:

	add R1, R1, R5				// dodamo u R1 adresu od rgb_matrix
	st R3, R1					// crtamo kursor na rgb_matrix poziciji (x,y)


count_frames:						// ovom rutinom softverski "usporavamo" izvrsavanje igrice
	ZERO(R0)
	inc R0, R0						// R0 sada pokazuje na frame_cnt
	ld R1, R0						// ucitamo frame_cnt u registar R1

	inc R0, R0
	ld R2, R0						// ucitamo max_frames u registar R2
	dec R0, R0

	inc R1, R1
	st R1, R0						// upisemo inkremnt frame_cnt u memoriju
	sub R2, R2, R1					// poredimo frame_cnt i max_frames, ako se ne upali z flag,
	jmpnz frame_sync_rising_edge	// znaci da nismo izbrojali sve frejmove pa skacemo ponovo na crtanje

	ZERO(R7)						// ako dodjemo ovde onda je proslo dovoljno frejmova, pa cemo da registrujemo input
	st R7, R0						// restartujemo frame_cnt


move_cursor:
	ZERO(R0)
	ld R0, R0					// postavljamo R0 da pokazuje na koordinate kursora

	ld R1, R4					// upisujemo x pomeraj kontrola u R1
	inc R4, R4					// pomerimo se na citanje y pomeraja
	ld R2, R4					// upisujemo y pomeraj kontrola u R2
	dec R4, R4					// vracamo R4 da pokazuje na pb_dec adresu

	// Pomeranje po x osi
	ld R7, R0					// upisemo staru x koordinatu u R7
	add R1, R7, R1				// R1 sada sadrzi novu pomerenu x koordinatu
	jmps frame_sync_rising_edge	// ako je broj negativan (pokusavamo da izadjemo iz okvira ekrana)
	ZERO(R7)
	ld R7, R7					// R7 sadrzi makximalnu x koordinatu (broj 8)
	sub R7, R7, R1
	jmpz frame_sync_rising_edge	// ako je koordinata = 8 (pokusavamo da izadjemo iz okvira ekrana)
	st R1, R0					// upisujemo nazad u memoriju

	// Pomeranje po y osi
	inc R0, R0
	ld R7, R0					// upisemo staru y koordinatu u R7
	add R2, R7, R2				// R2 sada sadrzi novu pomerenu y koordinatu
	jmps frame_sync_rising_edge	// ako je broj negativan (pokusavamo da izadjemo iz okvira ekrana)
	ZERO(R7)
	ld R7, R7					// R7 sadrzi makximalnu y koordinatu (broj 8)
	sub R7, R7, R2
	jmpz frame_sync_rising_edge	// ako je koordinata = 8 (pokusavamo da izadjemo iz okvira ekrana)
	st R2, R0					// upisujemo nazad u memoriju
	dec R0, R0

	inc R4, R4
	inc R4, R4
	ld R7, R4					// proveravamo dal je centralni taster pritisnut
	dec R4, R4
	dec R4, R4

	and R7, R7, R7				// ako je u registru broj 1, z flag se nece upaliti
	jmpnz check_field			// pa onda skacemo na rutinu za proveru polja

	jmp frame_sync_rising_edge


check_field:
	ld R1, R0
	inc R0, R0
	ld R2, R0					// upisemo x i y koordinatu kursora u R1 i R2 registar
	inc R0, R0					// R0 sada pokazuje na koordinate prvog polja

	check_loop:
		ld R7, R0						// ako je -1 u registru, onda smo dosli do kraja niza polja
		jmps add_wrong_field			// dodajemo pogresno polje na kraj niza

		inc R0, R0
		ld R7, R0
		dec R0, R0
		sub R7, R7, R1					// proveravamo dal se poklapaju x koordinate polja u kursora
		jmpnz move_to_next_point_2

		inc R0, R0
		inc R0, R0
		ld R7, R0
		dec R0, R0
		dec R0, R0						// R0 ponovo pokazuje na stanje polja
		sub R7, R7, R2					// proveravamo dal se poklapaju y koordinate polja u kursora
		jmpnz move_to_next_point_2

		ld R7, R0
		and R7, R7, R7					// ako polje nije skriveni brod, ne menjamo stanje polja
		jmpnz frame_sync_rising_edge

		// ako dodjemo dovde, znaci da je kursor bio na skrivenom brodu
		ZERO(R7)
		inc R7, R7
		st R7, R0						// menjamo stanje polja u otkriveno

		ZERO(R3)
		inc R3, R3
		shl R3, R3
		shl R3, R3						// R3 pokazuje na promneljivu koja pamti koliko brodova je ostalo
		ld R7, R3
		dec R7, R7						// smanjujemo broj brodova
		st R7, R3						// cuvamo nazad u memoriji koliko brodova je ostalo
		jmp check_game_end				// vracamo se na proveru kraja igre

		move_to_next_point_2:
		inc R0, R0
		inc R0, R0
		inc R0, R0					// pomeramo R0 na sledece koordinate polja

		jmp check_loop


add_wrong_field:
	ZERO(R7)
	inc R7, R7
	inc R7, R7
	st R7, R0					// upisujemo 2 za novo polje (oznaka da je polje promaseno)

	inc R0, R0
	st R1, R0
	inc R0, R0
	st R2, R0					// upisujemo x i y koordinatu polja (iste koordinate kao kursor)

	inc R0, R0
	ZERO(R7)
	dec R7, R7
	st R7, R0					// upisujemo -1 na kraj (oznaka za kraj niza polja)

	jmp frame_sync_rising_edge

end:
	jmp end
