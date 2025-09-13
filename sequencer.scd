~bootMaudio.()
/*
===========
navigazione

usa:
b --> struttura dati che contiene tutti i children della view
~current --> bottone attuale (come child della view)
~total --> numero totale di bottoni
~navigazione --> bus che riceve ogni x.wait (routine) il valore di direzione
===========
*/
(
HID.findAvailable;
HID.postAvailable;
)
~myhid = HID.openAt(0);
// HID.debug = true;
// HID.debug = false;

~current = 0;
~total = 20*6; //20 tasti 6 corde - possibile fare variabili perché sono valori usati sotto
~navigazione = Bus.control;

/*
=========
fretboard

usa "b"
=========
*/
// Image.open(PathName(thisProcess.nowExecutingPath).parentPath++"fretboard.gif").bounds.height
/*
(
var i = Image.open(PathName(thisProcess.nowExecutingPath).parentPath++"fretboard.gif");
var ratio = i.bounds.width / i.bounds.height;
i.plot("", i.bounds.resizeBy(400, 400/ratio))
)
*/
//Y = 15 da sopra = hi e
//Y = 85 da sopra = low e


/*
====================================================================
altra versione GUI in cui non creo bottoni ogni volta ma faccio hide

TODO:
- [V] submit note e accordi nella gui
- [V] quando sono su "freq" nascondi btnsView
- aggiorna btnsView con l'accordo attuale (in base al sub premuto)

bug:
- [V} premo su subs e sparisce midinote (perché subfunction vede un array in quel punto)

- [V] creo key e premo subs. poi imposto note--> viene persa la programmazione precedente all'impostazione note
popUpMenu.items.do dentro fretboardRoll --> prende value di \freq (che parte da 0)

- [V] se premo su fretboard quando non c'è un sub (es nuovo beat), errore (ma non compromette niente)--> quindi la fretboardroll è visibile solo quando premo su un sub

- [V] se faccio + subs, clicco --> blank. ora se programmo un'altra key e poi imposto freq e cambio di nuovo nel menu su quell'altra key, rimane blank (non mostra la stringa con midinote ma il value è giusto, quello precedentemente programmato) finche non lo premo in questa nuova key

====================================================================
*/
//se eseguo dopo il cambio, aggiorna midinote nella nuova key
(
var stream, stream2;
stream = Pseq(e[\freq]).asStream.all.flat;
stream2 = Pseq(stream).asStream;
d.deepCollect(inf, {|it| it.string_(stream2.next)});

stream = Pseq(e[\n]).asStream.all.flat;
stream2 = Pseq(stream).asStream;
d.deepCollect(inf, {|it| it.value_(stream2.next)});
)



(
var currentBeat, currentSub, beatString, subString, subFunction, w, beatsView, beats, subsView, subs, addSubs, removeSubs,
keyView, textField, popUpMenu, updateMaster;

var translate = {|arr|
	var lowE = 52;
	var note = [arr[1]+1, arr[0]];
	var midivalue;
	note.postln;

	midivalue = 6 - note[0] * 5 + lowE //which string
	+ note[1] ; //which fret
	if(note[0] <= 2){midivalue = midivalue -1}; //b & e string skip

	// midivalue = 6 - note[0] * (note[0] <= 2).if(4, 5) + lowE + note[1]; //alt
	("midivalue: " + midivalue).postln;
	midivalue
};


var image = Image.open(PathName(thisProcess.nowExecutingPath).parentPath++"fretboard.gif");
var ratio = image.bounds.width / image.bounds.height;
var resizePixel = 400;
var xAdj = image.bounds.width + 400 / image.bounds.width;
var yAdj = image.bounds.height + (400/ratio) / image.bounds.height;
var imageBounds = image.bounds.resizeBy(resizePixel, resizePixel/ratio);
var fretboard = Window("sequencer", imageBounds.resizeBy(0,100)).front.alwaysOnTop_(true);
var imageView = View(fretboard, /*image.bounds*/imageBounds);
var btnsView = View(imageView, imageBounds/*image.bounds*/);
var btns =
Array.fill(6 //6 strings
	,{|j|

		Array.fill(20 //20 frets
			,
			{|i|
				Button(btnsView, Rect(30*i * xAdj + i + 5,
					13 * (j+1) * yAdj
					, 14,14))
				.states_([
					[ /*i*(j+1)*/"", Color.black, Color(1,1,1,0.3)],
					[ /*i*(j+1)*/"", Color.black, Color(0.8, 0.0,0.2,0.8)],

				])
				.action_({
					|btn|
					if(btn.value == 1){

						// translate.(i, j);
						// currentBeat.postln;
						// currentSub.postln;
/*

						if(e[\freq][currentBeat].isEmpty.not){
							//crea un array e crea il nuovo bottone (array anche in d). fai sort per incolonnarli
							e[\freq][currentBeat] = e[\freq][currentBeat].add([j, i]);
							//tasto +

						}{

							//salva [j, i] in e[freq] in modo da ricostruire quando premo sul sub
							e[\freq][currentBeat][currentSub] = [j, i];

						};
						*/
						//incolonna btns in caso di accordi (più note nello stesso beat e sub)



						//test con midi
						if(e[\freq][currentBeat][currentSub][0].isNil){
							e[\freq][currentBeat][currentSub] = [translate.([i, j])]; //elimina nil iniziale
						}
						{
							//accordo

							//aggiorna tutti gli e[\item] // updateMaster.(true);
							popUpMenu.items.do{|item|
								// if(item == "freq"){}{e[item.asSymbol] = d.deepCollect(inf, {|it| it.value/*it.string*/})}
								if(item == "freq"){

									e[\freq][currentBeat][currentSub] = e[\freq][currentBeat][currentSub].add(translate.([i, j]));
								}
								{
									e[item.asSymbol][currentBeat][currentSub] = e[item.asSymbol][currentBeat][currentSub].add(0)
								}
							};

							//addsubs
							("size dei btn " ++ d[currentBeat][currentSub].size).postln;
							d[currentBeat][currentSub] = d[currentBeat][currentSub].add(

								Button(subsView, Rect(15 * currentSub, 5+ (14* d[currentBeat][currentSub].size), 14, 14))
								.states_(
									Array.fill(10, {|i| [i, Color.black, Color(1, i.linlin(0,9, 0.96, 0.0), 0)]})
								).action_(subFunction)
								.string_("nil")
							);

							beats[currentBeat].valueAction_(0) //solo visibilità

						};
						d[currentBeat][currentSub].deepCollect(inf, {|it| it.valueAction_(0)}); //fa aggiornare numero anche in altre key

						//aggiorna subs (solo stringa e non value -> in "e" rimane il valore salvato
						// d[currentBeat][currentSub].deepCollect(inf, {|it| if(it.isNil.not){it.string_(translate.([i, j])) } }); //CANCELLARE

						// d[0][0].string_(55)

						/*
						[1, 0] == open hi  e
						[6, 0] == open low E

						midi translation:
						var value = [6, 0] --> 52 + value[1]
						[5, 0] --> 52 + 5 + value[1]
						*/


					}{
						//bottone spento
						// toglie btn da --> e[\freq][currentBeat][currentSub]
						//cambia gui togliendo btns
					}
				})
			}
		)
});

imageView.setBackgroundImage(image, 11); //centrale rispetto alla view (scaled)
// imageView.backgroundImage_(image);
btnsView.background=Color(0,0,0,0.2);
b = btnsView.children; //usato nella hidfunc

~navigazione.set(0);
~current = 0;



d = List();

currentBeat = 0;
currentSub = 0;
beatString = StaticText().string_("current beat " ++ currentBeat);
subString = StaticText().string_("current sub " ++ currentSub);
w = Window("asd", Rect(0,0, 400,400)).front.alwaysOnTop_(true);
beatsView = ScrollView(w, w.bounds.resizeBy(-200,-300)).minWidth_(200).maxWidth_(200);
subsView = ScrollView(w, w.bounds/*.resizeBy(-200,-300)*/)/*.minWidth_(200).maxWidth_(200)*/;

subFunction = {|self|
	var state = self.value;
	if(popUpMenu.item=="freq"){
		self.value_(state-1);
		// "sono freq".postln;
		//aggiorna fretboardroll con l'accordo

	}
	{
		//aggiorna struttura dati "e"
		("aggiorno e per " ++ popUpMenu.item).postln;
		e[popUpMenu.item.asSymbol] = d.deepCollect(inf, {|it| it.value/*it.string*/});
	};

	// currentSub = subsView.children.select{|it| it.visible}.indexOf(self); /////////////////errore sub quando faccio accordo, perché li mette in un vettore - quindi meglio trovare la pos in "d"
	d[currentBeat].do{|it i| if(it.includes(self)){currentSub = i}};
	subString.string_("current sub " ++ currentSub);

	// if(e[\freq][currentBeat][currentSub].isArray){self.string_(translate.(e[\freq][currentBeat][currentSub]))}; //IN CASO DI ACCORDI PUò NON FUNZIONARE
	self.string_(e[\freq][currentBeat][currentSub][d[currentBeat][currentSub].indexOf(self)]); //accordo

	if(popUpMenu.item=="freq"){}{self.value_(state)};
};

//crea bottoni di beatsView e mette in "d" [indice, subsBtn]
beats = Array.fill(40, {|i| Button(beatsView, Rect(15*i, 5, 14, 14))
	.states_([[i]]) //non faccio i+1 perché sotto lo uso per insert e lascerebbe l'ultimo senza niente
	.action_(
		{|self|
			//quando premo su un bottone di clock beat riempie subsView
			currentBeat = self.states[0][0];
			beatString.string_("current beat " ++ currentBeat);

			subsView.children.do(_.visible_(false)); //svuota subsView

			d[self.states[0][0]].deepCollect(inf, {|it| it.visible_(true)});

			if(d[currentBeat][currentSub].isNil){btnsView.visible_(false)}{btnsView.visible_(true)}

		}
	)
}).do{|item i|
	d.insert(item.states[0][0],
		[
			/*Button(subsView, Rect(0, 5, 14, 14))
			.states_(
				Array.fill(10, {|i| [i, Color.black, Color(1, i.linlin(0,9, 0.96, 0.0), 0)]})
			).action_(subFunction)*/
		]
	)

}; //questo ciclo resetta (non proprio) "d" ogni volta che apro la GUI


beats[currentBeat].valueAction_(0); //nasconde tutti tranne quello corrente - all'inizio, l'ultimo è in cima a tutti


//scelta key
keyView = View(w);
textField = TextField(keyView);
popUpMenu = PopUpMenu(keyView);
popUpMenu.items = ["freq"];
popUpMenu.action_{|menu|
	menu.item.postln;

	if(menu.item == "freq"){
		btnsView.visible_(true);
		d.deepCollect(inf, {|it| it.value_(0)});

	}{
		var valueFunction, stringFunction;
		btnsView.visible_(false);

		valueFunction = {
			var stream, stream2;
			stream = Pseq(e[menu.item.asSymbol]).asStream.all.flat;
			stream2 = Pseq(stream).asStream;
			d.deepCollect(inf, {|it| it.value_(stream2.next)});

		};
		stringFunction = {
			var stream, stream2;
			stream = Pseq(e[\freq]).asStream.all.flat;
			stream2 = Pseq(stream).asStream;
			d.deepCollect(inf, {|it| it.string_(stream2.next)});

		};

		//perché funziona? boh
		valueFunction.();
		stringFunction.();
		valueFunction.();
	};


	addSubs.visible_(menu.item == "freq");
	removeSubs.visible_(menu.item == "freq");
};
keyView.layout = VLayout(HLayout(popUpMenu,
	Button(keyView)
.states_([[ "+" ]])
.action_{
		textField.string.postln;

		if(popUpMenu.items.select{|it| it.asSymbol == textField.string.asSymbol}.isEmpty)
		{
			"non include".postln;
			popUpMenu.items = popUpMenu.items.add(textField.string);
			e[textField.string.asSymbol] = d.deepCollect(inf, {0});
		}
		{"include".postln};
			popUpMenu.items.postln;
},
Button(w)
.states_([[ "-" ]])
.action_{

		if((popUpMenu.item == "freq").not){
			popUpMenu.items.remove(popUpMenu.item);
			e.removeAt(popUpMenu.item.asSymbol);
			popUpMenu.valueAction_(0);
		};
			popUpMenu.items.postln;

}),
textField);

//VALIDO PER QUANDO AGGIUNGEVO UN BOTTONE ALL'INIZIO: è selezionata freq, la devo aggiungere alla struttura dati esterna altrimenti al cambio nel menu sballa
//fa funzionare il codice. alternativa--> e.add(\freq->[]) che poi va riempito
e[popUpMenu.item.asSymbol] = d.deepCollect(inf, {nil}); //vedi istruzione finale (se può sostituire questa)

updateMaster = {|bool|
	//aggiorna tutti gli item e il corrispettivo e[\item]
	popUpMenu.items.do{|item|

		if(item == "freq")
		{
			if(bool){
				//aggiungo se true
				e[\freq][currentBeat] = e[\freq][currentBeat].add([nil]);
			}{
				e[\freq][currentBeat].pop
			}
		}
		{
			e[item.asSymbol][currentBeat] = e[item.asSymbol][currentBeat].add([0])
			// e[item.asSymbol][currentBeat] = d.deepCollect(inf, {|it| it.value/*it.string*/})
		}
	};
};

//layout totale
addSubs = Button(bounds: Rect(width: 10, height:10))
.states_([["+"]])
.action_{
	d[currentBeat] = d[currentBeat].add(

		Button(subsView, Rect(15*d[currentBeat].size, 5, 14, 14))
		.states_(
			Array.fill(10, {|i| [i, Color.black, Color(1, i.linlin(0,9, 0.96, 0.0), 0)]})
		).action_(subFunction)
		.string_("nil")
	);
	d[currentBeat].put(d[currentBeat].size-1, [d[currentBeat].last]);

	//aggiorna tutti gli e[\item]
	updateMaster.(true);


	beats[currentBeat].valueAction_(0) //solo visibilità
};
removeSubs = Button(bounds: Rect(width: 10, height:10)).states_([["-"]])
.action_{
	if(d[currentBeat].size > 0) {
		d[currentBeat].pop; 	//decidere nel pattern come gestire 0 subs (se ci deve essere 1...)

		//aggiorna tutti gli item e il corrispettivo e[\item]
		updateMaster.(false);

	};
	beats[currentBeat].valueAction_(0)};


View(w, Rect(0,0, 400,200)).layout =
VLayout(
	keyView,
	HLayout(beatString,	subString),

	HLayout(
		StaticText().string_("clock beat"),
		beatsView
	),
	HLayout(
		StaticText().string_("beat subs"),
		addSubs,
		removeSubs,
		subsView
	)

);
beatsView.background = Color.white;
addSubs.valueAction_(0); //inizia con almeno un bottone
// e[popUpMenu.item.asSymbol][currentBeat][currentSub] = 60;
w
)


/*
(
var translate = {|i j|
	var lowE = 52;
	var note = [j+1, i];
	var midivalue;
	note.postln;

	midivalue = 6 - note[0] * 5 + lowE //which string
	+ note[1] ; //which fret
	if(note[0] <= 2){midivalue = midivalue -1}; //b & e string skip

	// midivalue = 6 - note[0] * (note[0] <= 2).if(4, 5) + lowE + note[1]; //alt
	("midivalue: " + midivalue).postln;
	midivalue
};
var image = Image.open(PathName(thisProcess.nowExecutingPath).parentPath++"fretboard.gif");
var ratio = image.bounds.width / image.bounds.height;
var resizePixel = 400;
var xAdj = image.bounds.width + 400 / image.bounds.width;
var yAdj = image.bounds.height + (400/ratio) / image.bounds.height;
var imageBounds = image.bounds.resizeBy(resizePixel, resizePixel/ratio);
var fretboard = Window("sequencer", imageBounds.resizeBy(0,100)).front.alwaysOnTop_(true);
var imageView = View(fretboard, /*image.bounds*/imageBounds);
var btnsView = View(imageView, imageBounds/*image.bounds*/);
var btns =
Array.fill(6 //6 strings
	,{|j|

		Array.fill(20 //20 frets
			,
			{|i|
				Button(btnsView, Rect(30*i * xAdj + i + 5,
					13 * (j+1) * yAdj
					, 14,14))
				.states_([
					[ /*i*(j+1)*/"", Color.black, Color(1,1,1,0.3)],
					[ /*i*(j+1)*/"", Color.black, Color(0.8, 0.0,0.2,0.8)],

				])
				.action_({
					|btn|
					if(btn.value == 1){

						translate.(i, j);

						//salva [j+1, i] in e[freq] in modo da ricostruire quando premo sul sub

						// e[\freq][currentBeat][currentSub] = e[\freq][currentBeat][currentSub].add(note);
						//cambia gui incolonnando btns in caso di accordi (più note nello stesso beat e sub)
						//aggiorna subs (solo stringa e non value -> in "e" rimane il valore salvato
						// d[0][0].string_(55)

						/*
						[1, 0] == open hi  e
						[6, 0] == open low E

						midi translation:
						var value = [6, 0] --> 52 + value[1]
						[5, 0] --> 52 + 5 + value[1]
						*/


					}{
						//bottone spento
						// toglie btn da --> e[\freq][currentBeat][currentSub]
						//cambia gui togliendo btns
					}
				})
			}
		)
});

imageView.setBackgroundImage(image, 11); //centrale rispetto alla view (scaled)
// imageView.backgroundImage_(image);
btnsView.background=Color(0,0,0,0.2);
b = btnsView.children; //usato nella hidfunc

~navigazione.set(0);
~current = 0;
)


*/






//GAMEPAD
(
//frecce - valori monkaS
~myhid.findElementWithUsage(57,1)[0].action = {
	// var v = value.round(0.1);//.postln;
	//0.3 dx
	//0.9 sx
	//0.0 sopra
	//0.6 sotto
	//-0.1 release
	|value raw|
	var v = value.round(0.1);

	if(v > -0.05){

		if(v < 0.5){
			if(v > 0.0){"dx".postln;~navigazione.set(1)}
			{"sopra".postln; ~navigazione.set(-20)}
		}{
			if(v < 0.7)
			{"sotto".postln; ~navigazione.set(20)}
			{"sx".postln; ~navigazione.set(-1)}
		}
	}{
		~navigazione.set(0);
	}

};

HIDFunc.usage( { |...args| var val = args[1].linlin(0,65535, -1,1).round(0.01);
	~navigazione.set(val);
	// val.postln;
}, \X );

HIDFunc.usage( { |...args| var val = args[1].linlin(0,65535, -20,20 //legato al numero di tasti per corda
).round(20);
	~navigazione.set(val);
// val.postln;
}, \Y );

//tasto 'A' - NB per più di 2 stati, devo cambiare valore di modulo
~myhid.findElementWithUsage(1, 9)[0].action = {
	|value|
	//stu burdell perché quando rilascio il tasto A, riceve 0 e spegnerebbe il tasto sul sequencer
	if(value == 1){ //onkeydown aumenta il valore del btn di 1 e fai modulo
		{b[~current].valueAction_(b[~current].value + 1 % 2)}.defer
	}
};
//dorsale sx - cancella tutto - se ci sono altre strutture dati su cui vanno a finire i valori midi, vanno cancellati anche lì
~myhid.findElementWithUsage(5, 9)[0].action = {
	|value|
	if(value == 1){
		{b.do(_.valueAction = 0)}.defer
	}
};



fork{loop{
	~current = ~current + ~navigazione.getSynchronous.round;
	~current = ~current % ~total;
	b[~current].focus;
	0.1.wait;

}}
)


/*
==========
clock beat

usa:
d --> struttura dati che associa numero di beat con corrispettivo numero di suddivisioni
beats (locale) --> struttura dati che contiene bottoni (che rappresentano beats). se li premo cambia current beat e aggiorna view che contiene suddivisioni

TODO:
- [V] quando premo + e - aggiorna anche numero di subs nelle altre view e nella/e struttura dati che le controllano--- decidere come gestire (anche dal punto di vista grafico)
- [?] aggiungere action ai bottoni subs in modo da vedere lo stato delle key
- [V] risolvere problema di suddivisione (struttura dati e gui) per accordi - perché sono suonati nello stesso beat
- fare tasti + e - per clock beat e dire nei pattern che solo quel numero di beat va riprodotto (poi loop o altro) - magari anche un sottinsieme
==========
*/



/*~beats = List()
~beats = ~beats.insert(0, 0)
// ~beats[1] = ~beats[1].add(Button.new())*/



// Array.fill(40, {|i| Button().states_([[i+1]])}).do{|item| d.insert(item.states[0][0], [Button.new()])}
//scrollbar???
/*
(
var currentBeat, beatString, w, beatsView, beats, subsView, subs;
d = List();

currentBeat = 0; //parto da 0 in modo che se premo "+" all'inizio, non sminchia niente
beatString = StaticText().string_("current beat " ++ currentBeat);
w = Window("asd", Rect(0,0, 400,400)).front.alwaysOnTop_(true);
beatsView = ScrollView(w, w.bounds.resizeBy(-200,-300)).minWidth_(200).maxWidth_(200);
subsView = ScrollView(w, w.bounds.resizeBy(-200,-300)).minWidth_(200).maxWidth_(200);

beats = Array.fill(40, {|i| Button(beatsView, Rect(15*i, 5, 14, 14)).states_([[i+1]])})
.do{|item i| d.insert(item.states[0][0],
	1//perche no buttin???

)}; //questo ciclo resetta "d" ogni volta che apro la GUI

//quando premo su un bottone di clock beat riempie subsView
//in generale: svuota view dipendenti; aggiorna con i valori salvati in una struttura dati (es velocity)
beats.do{|item|
	item.action_({|self|
		currentBeat = self.states[0][0];
		beatString.string_("current beat " ++ currentBeat);


		subsView.removeAll; //svuota subsView

		//BOTTONI SUBS
		d[self.states[0][0]].do{|i|
			//riempie subsView con il numero di btn giusto
			Button(subsView, Rect(15*i, 5, 14, 14))
			.states_(
				Array.fill(10, {|i| [i, Color.black, Color(1, i.linlin(0,9, 0.96, 0.0), 0)]})
			).action_({|self|

			})
		};


	}
)};

View(w, Rect(0,0, 400,200)).layout =
VLayout(
	beatString,

	HLayout(
	StaticText().string_("clock beat"),
	beatsView
),
	HLayout(
	StaticText().string_("beat subs"),
		Button(bounds: Rect(width: 10, height:10)).states_([["+"]])
		.action_{d[currentBeat] = d[currentBeat] + 1; beats[currentBeat-1].valueAction_(0)},
		Button(bounds: Rect(width: 10, height:10)).states_([["-"]])
		.action_{if(d[currentBeat] > 0) {d[currentBeat] = d[currentBeat] - 1}; //decidere nel pattern come gestire 0 subs (se ci deve essere)
			beats[currentBeat-1].valueAction_(0)},
	subsView
)

);
beatsView.background = Color.white;
w
)
*/




/*
===============================================================
test demo - programmo ogni evento (accordi, note singole, subs)
===============================================================
*/

(
var w = Window("");
z =
List[
	[Button(w).states_([ [ 1,Color.white, Color.grey ] ]) ],
	[Button(w).states_([[ 1,Color.white, Color.grey ]]), Button(w).states_([[ 2,Color.white, Color.grey ]]) ],
	[
		[
			Button(w).states_([[ 1,Color.white, Color.grey ]]),
			Button(w).states_([[ 2,Color.white, Color.grey ]]),
			Button(w).states_([[ 6,Color.white, Color.grey ]])
		],
		Button(w).states_([[ 3,Color.white, Color.grey ]])
	],
	[
		Button(w).states_([[ 1,Color.white, Color.grey ]]) ,
		Button(w).states_([[ 2,Color.white, Color.grey ]]) ,
		Button(w).states_([[ 3,Color.white, Color.grey ]]) ,
		Button(w).states_([[ 1,Color.white, Color.grey ]]) ,
		[
			Button(w).states_([[ 4,Color.white, Color.grey ]]),
			Button(w).states_([[ 4,Color.white, Color.grey ]]),
			Button(w).states_([[ 4,Color.white, Color.grey ]]),
			Button(w).states_([[ 4,Color.white, Color.grey ]])
		],
	],


];
w.front;
)


(
//ogni volta che programmo un beat subs per quella key - poi quando cambio key, carico nei bottoni quei valori salvati (all'inizio tutti a 0)
e.velocity = z.deepCollect(inf, {|i| i.string})
/*
//bello ma inutile
z.collect{|it| if(it.flat.size > it.size)
	{
		//contiene array
		it.collect{|item|
			if(item.isArray)
			{item.collect(_.string)}
			{item.string}
		}
	}
	{
		//non contiene array
		it.collect(_.string)
	}
}*/
)



/*
========================
strutture dati probabili
========================
*/
(
freq:    [ [], //1 beat - contiene chord o singole note
	[],
	[] ],
velo:    [ [], [], [] ],
dur:     [ [], [], [] ],
legato:  [ [], [], [] ],
rate:    [ [], [], [] ],
)

//alt da chiarire...
[
	[
		(), //1 beat
		(),
		(),
	],
	[],
	[]
]