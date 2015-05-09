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


+step(X) <- !inform_friends;!action;!inform_friends;!action;!inform_friends;!action.


+!find_cell_to_explore : grid_size(GridX, GridY) & pos(PosX,PosY) & visibility(C)<-
	for( .range(CntX,C,GridX-1) ) {
		for( .range(CntY,C,GridY-1) ) {
			if( not destination(_,_)) {
				A = GridX-1-CntX;
				B = GridY-1-CntY;
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



+!action: visit_points(V) & max_visit_points(V) <-
	.print("KONEC");
	do(skip).
+!action: not destination(_,_) <-
	.print("hledam novy cil");  
	.abolish(destination(_,_)); 
	!find_cell_to_explore;
	!action.
+!action: destination(DX,DY) & pos(DX,DY) <-
	.print("uz jsem tu...");  
	.abolish(destination(_,_));
	!find_cell_to_explore;
	!action.
+!action <-
	?calc_next_move(X,Y,D);
	.print("Pujdu do ", X, ", ", Y);
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

+gold(X,Y) : friend(F1) & friend(F2) & (F1 \== F2) <-
	+found_gold(X,Y);
	.send(F1, tell, found_gold(X,Y));
	.send(F2, tell, found_gold(X,Y)).
+wood(X,Y) : friend(F1) & friend(F2) & (F1 \== F2) <-
	+found_wood(X,Y);
	.send(F1, tell, found_wood(X,Y));
	.send(F2, tell, found_wood(X,Y)).
	
