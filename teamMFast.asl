visibility(1).
visit_points(0).

free.

// init
!start.
+!start : .my_name(Name) & grid_size(X, Y) & visibility(C) & friend(F1) & friend(F2) & (F1 \== F2) <-
	.send(F1, tell, fast_agent(Name));
	.send(F2, tell, fast_agent(Name));
	A = math.floor((X-1)/(2*C+1)) + 1;
	B = math.floor((Y-1)/(2*C+1)) + 1;
	D = A*B;
	+max_visit_points(D).


+step(X) <- -move_on;-picking;!inform_friends;!action;!inform_friends;!action;!inform_friends;!action.


+!find_cell_to_explore : grid_size(GridX, GridY) & pos(PosX,PosY) & visibility(C)<-
	for( .range(CntX,C,GridX-1) ) {
		for( .range(CntY,C,GridY-1) ) {
			if( not destination(_,_)) {
				A = CntX;
				B = CntY;
				if (((CntX mod (2*C+1)) == C) & ((CntY mod (2*C+1)) == C) & not(visited_point(A,B))) {
					+destination(A,B);
					+visited_point(A,B);
					W = V + 1;
					-visit_points(V);+visit_points(W)
				}
			}
		}	
	}.
// next direction and its position
calc_next_move(NX,PY,left)  :-  pos(PX,PY) & destination(DX,DY) & PX > DX & NX = PX-1.
calc_next_move(NX,PY,right) :-  pos(PX,PY) & destination(DX,DY) & PX < DX & NX = PX+1.
calc_next_move(PX,NY,up)    :-  pos(PX,PY) & destination(DX,DY) & PY > DY & NY = PY-1.
calc_next_move(PX,NY,down)  :-  pos(PX,PY) & destination(DX,DY) & PY < DY & NY = PY+1.

calc_distance(PosX,PosY,X,Y,D) :- D = math.abs(PosX - X) + math.abs(PosY-Y).

find_nearest_gold(D,PosX,PosY,X,Y) :- found(gold,X,Y) & calc_distance(PosX,PosY,X,Y,D).
find_nearest_wood(D,PosX,PosY,X,Y) :- found(wood,X,Y) & calc_distance(PosX,PosY,X,Y,D).

//init
+!action: not slow_agent(_) | not middle_agent(_) <- !action.

// prave doslo k vyzvednuti => musim prenest suroviny
+!action: ( not carrying_gold(0) | not carrying_wood(0)) & not move_on  <- .print("cekam na presun");!action.
// vyzvednuti s jinym agentem
+!action: pos(DX,DY) & ( found(gold,DX,DY) | found(wood,DX,DY) ) & ally(DX,DY) & step(S) & pick_in(S) <-
	.print("nakladam surovinu");
	.abolish(destination(_,_));
	do(pick);
	-pick_in(S);
	-found(gold,DX,DY);
	-found(wood,DX,DY);
	-gold(DX,DY);
	-wood(DX,DY);
	.abolish(destination(_,_));
	+wait_for_transfer;
	.print("surovina nalozena").
// cekani na dalsiho agenta
+!action: pos(DX,DY) & ( found(gold,DX,DY) | found(wood,DX,DY) ) & not ally(DX,DY) <-
	.print("ale cekam na kolegu1");
	do(skip).
+!action: pos(DX,DY) & ( found(gold,DX,DY) | found(wood,DX,DY) ) & moves_per_round(M) & not moves_left(M) <-
	.print("ale cekam na kolegu2");
	do(skip).
// tady uz nic neni
+!action: pos(DX,DY) & destination(DX,DY) & ( found(gold,DX,DY) | found(wood,DX,DY) ) & not gold(DX,DY) & not wood(DX,DY) & slow_agent(F1) & middle_agent(F2) <-
	.print("tady uz nic neni");
	-found(gold,DX,DY);
	-found(wood,DX,DY);
	.send(F1, untell, found(gold,DX,DY));
	.send(F2, untell, found(gold,DX,DY));
	.send(F1, untell, found(wood,DX,DY));
	.send(F2, untell, found(wood,DX,DY));
	-destination(DX,DY);
	!action.
// nasel jsem blizsi zlato
+!action: destination(DX,DY) & pos(PosX,PosY) & gold(GX,GY) & (DX \== GX | DY \== GY) & calc_distance(PosX,PosY,DX,DY,D) & calc_distance(PosX,PosY,GX,GY,G) & G < D & middle_agent(Name) <-
	.print("nasel jsem blizsi cil");
	.abolish(destination(_,_));
	+destination(GX,GY);
	.send(Name, achieve, update_target(GX,GY));
	!action.
// nasel jsem blizsi drevo
+!action: destination(DX,DY) & pos(PosX,PosY) & wood(GX,GY) & (DX \== GX | DY \== GY) & calc_distance(PosX,PosY,DX,DY,D) & calc_distance(PosX,PosY,GX,GY,G) & G < D & middle_agent(Name) <-
	.print("nasel jsem blizsi cil");
	.abolish(destination(_,_));
	+destination(GX,GY);
	.send(Name, achieve, update_target(GX,GY));
	!action.
// jsem na miste prohledani
+!action: destination(DX,DY) & pos(DX,DY) <-
	.print("uz jsem tu...");  
	.abolish(destination(_,_));
	!find_cell_to_explore;
	!action.
// novy cil - zlato
+!action: not destination(_,_) & found(gold,_,_) & pos(PosX,PosY)  <-
	.findall(D,(found(gold,A,B) & calc_distance(PosX,PosY,A,B,D)),Distances);
	.min(Distances,Min);
	?find_nearest_gold(Min,PosX,PosY,A,B);
	+destination(A,B);
	.print("zmena cile -> zlato na pozici ", A, ", ", B);
	!action.
// novy cil - drevo
+!action: not destination(_,_) & found(wood,_,_) & pos(PosX,PosY)  <-
	.findall(D,(found(wood,A,B) & calc_distance(PosX,PosY,A,B,D)),Distances);
	.min(Distances,Min);
	?find_nearest_wood(Min,PosX,PosY,A,B);
	+destination(A,B);
	.print("zmena cile -> wood na pozici ", A, ", ", B);
	!action.
// novy cil - prohledavani mapy
+!action: not destination(_,_) & visit_points(V) & max_visit_points(W) & V < W <-
	!find_cell_to_explore;
	!action.
// mapa prohledana, suroviny posbirany
+!action: visit_points(V) & max_visit_points(V) & not destination(_,_) & not found(gold,_,_) & not found(wood,_,_) <-
	.print("KONEC");
	do(skip).
// pohyb
+!action <-
	?calc_next_move(X,Y,D);
	.print("Pujdu do ", X, ", ", Y);
	+visited_point(X,Y);
	do(D).
 
+!inform_friends : visibility(C) & pos(PosX,PosY) & friend(F1) & friend(F2) & (F1 \== F2) & grid_size(GridX, GridY) <-
	for( .range(CntX,-C,C) ) {
		for( .range(CntY,-C,C) ) {
			if((PosX + CntX >= 0) & (PosY + CntY >= 0) & (PosX + CntX <= GridX) & (PosY + CntY <= GridY)) {
				A = PosX + CntX; B = PosY + CntY;
				+explored(PosX + CntX, PosY + CntY);
				.send(F1, tell, explored(A,B));
				.send(F2, tell, explored(A,B));
			}
		}	
	}.
+!inform_friends <- !inform_friends.

+gold(X,Y) : friend(F1) & friend(F2) & (F1 \== F2) <-
	+found(gold,X,Y);
	.send(F1, tell, found(gold,X,Y));
	.send(F2, tell, found(gold,X,Y)).
+wood(X,Y) : friend(F1) & friend(F2) & (F1 \== F2) <-
	+found(wood,X,Y);
	.send(F1, tell, found(wood,X,Y));
	.send(F2, tell, found(wood,X,Y)).
