visibility(1).
visit_points(0).

free.

// init
!start.
+!start : grid_size(X, Y) & visibility(C) <-
	A = math.floor((X-1)/(2*C+1)) + 1;
	B = math.floor((Y-1)/(2*C+1)) + 1;
	D = A*B;
	+max_visit_points(D).


+step(X) <- -picking;!inform_friends;!action;!inform_friends;!action;!inform_friends;!action.


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

find_nearest_gold(D,PosX,PosY,X,Y) :- found_gold(X,Y) & calc_distance(PosX,PosY,X,Y,D).
find_nearest_wood(D,PosX,PosY,X,Y) :- found_wood(X,Y) & calc_distance(PosX,PosY,X,Y,D).


// tady uz nic neni
+!action: pos(DX,DY) & ( found_gold(DX,DY) | found_wood(DX,DY) ) & not gold(DX,DY) & not wood(DX,DY) & friend(F1) & friend(F2) & (F1 \== F2) <-
	.print("tady uz nic neni");
	-found_gold(DX,DY);
	-found_wood(DX,DY);
	.send(F1, untell, found_gold(DX,DY));
	.send(F2, untell, found_gold(DX,DY));
	.send(F1, untell, found_wood(DX,DY));
	.send(F2, untell, found_wood(DX,DY));
	!action.
// vyzvednuti s jinym agentem
+!action: destination(DX,DY) & pos(DX,DY) & ( found_gold(DX,DY) | found_wood(DX,DY) ) & ally(DX,DY) <-
	.print("nakladam surovinu");
	.abolish(destination(_,_));
	do(pick);
	+picking;
	.print("surovina nalozena").
// cekani na dalsiho agenta
+!action: destination(DX,DY) & pos(DX,DY) & ( found_gold(DX,DY) | found_wood(DX,DY) ) <-
	.print("ale cekam na kolegu");
	do(skip).
// nasel jsem blizsi zlato
+!action: destination(DX,DY) & pos(PosX,PosY) & gold(GX,GY) & (DX \== GX | DY \== GY) & calc_distance(PosX,PosY,DX,DY,D) & calc_distance(PosX,PosY,GX,GY,G) & G < D & middle_agent(Name) <-
	.print("nasel jsem blizsi cil");
	.abolish(destination(_,_));
	+destination(GX,GY);
	.send(Name, achieve, update_target(GX,GY));
	!action.
// nasel jsem blizsi drevo
+!action: destination(DX,DY) & pos(PosX,PosY) & wood(GX,GY) & (DX \== GX | DY \== GY) & calc_distance(PosX,PosY,DX,DY,D) & calc_distance(PosX,PosY,GX,GY,G) & G < D <-
	.print("nasel jsem blizsi cil");
	.abolish(destination(_,_));
	+destination(GX,GY);
	!action.
// jsem na miste prohledani
+!action: destination(DX,DY) & pos(DX,DY) <-
	.print("uz jsem tu...");  
	.abolish(destination(_,_));
	!find_cell_to_explore;
	!action.
// novy cil - zlato
+!action: not destination(_,_) & found_gold(_,_) & pos(PosX,PosY)  <-
	.print("zmena cile -> zlato");
	.findall(D,(found_gold(A,B) & calc_distance(PosX,PosY,A,B,D)),Distances);
	.min(Distances,Min);
	?find_nearest_gold(Min,PosX,PosY,A,B);
	+destination(A,B);
	!action.
// novy cil - drevo
/*+!action: not destination(_,_) & found_wood(_,_) & pos(PosX,PosY)  <-
	.print("zmena cile -> drevo");
	.findall(D,(found_wood(A,B) & calc_distance(PosX,PosY,A,B,D)),Distances);
	.min(Distances,Min);
	?find_nearest_wood(Min,PosX,PosY,A,B);
	+destination(A,B);
	!action.*/
// novy cil - prohledavani mapy
+!action: not destination(_,_) & visit_points(V) & max_visit_points(W) & V < W <-
	!find_cell_to_explore;
	!action.
// mapa prohledana, suroviny posbirany
+!action: visit_points(V) & max_visit_points(V) & not destination(_,_) & not found_gold(_,_) & not found_wood(_,_) <-
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
	+found_gold(X,Y);
	.send(F1, tell, found_gold(X,Y));
	.send(F2, tell, found_gold(X,Y)).
+wood(X,Y) : friend(F1) & friend(F2) & (F1 \== F2) <-
	+found_wood(X,Y);
	.send(F1, tell, found_wood(X,Y));
	.send(F2, tell, found_wood(X,Y)).
	
