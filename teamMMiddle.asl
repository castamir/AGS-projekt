/*
Commit #10: Pohyb funguje. Otestovane na vsetkom, co ma napadlo.
Z cyklickych situacii sa agent dostane tak, ze odsleduje druhe prejdenie rovnakou trasou aspon o dlzke 4,
a potom z nej vyskoci.

explored(X,Y) - agent preskumal pole [X,Y] - videl ho
found(obstacle|gold|wood,X,Y) - na policku [X,Y] je prekazka/zlato/drevo. odosielaju sa zatial len informacie o surovinach
substep(X) - step(Y) pocita kola, substep(X) pocita pocet krokov agenta (teda fast ma napr. X = 3*Y) - nutne pre backtracking
was_on(X,Y,Z) - agent sa v podkroku (substep) Z nachadzal na pozicii [X,Y]. Po dokonceni ciela sa tieto informacie zmazu.
can_go(up|right|left|down) - agent sa moze posunut danym smerom - policko je v ramci mriezky a agent na nom este nebol (was_on)
returning(Step) - agent sa od kroku Step vracia naspat po svojich krokoch, podla was_on.
gold(X,Y); wood(X,Y), obstacle(X,Y) - na [X,Y] je zlato/drevo/prekazka
last_move(up|right|left|down) - smer posledneho kroku

!goSomewhere(X,Y) - spojene so znalostou goSomewhere(X,Y): agent ide na poziciu [X,Y]. sklada sa len z cielov getMovement a goToSpecificPoint.
!getMovement(X,Y) - zisti, na ktore policka okolo agenta je mozne prejst pomocou do(Direction) do was_on
!goToSpecificPoint(X,Y) - 
!doMove(Direction) - vykonanie pohybu danym smerom - odporucam pouzivat namiesto do(Dir) - doMove uchovava informacie navyse
!moveOrder(A,B,C,D) - priorita pohybov: ak mozem ist smerom A, idem smerom A. ak nie a ak mozem ist smerom B, idem smerom B...
*/

visibility(1).

!start.
+!start : .my_name(Name) & friend(F1) & friend(F2) & (F1 \== F2) <-
	.send(F1, tell, middle_agent(Name));
	.send(F2, tell, middle_agent(Name));
. 

/*+step(0): depot(DX,DY) <-
	if(not(substep(_))) { +substep(0); }
	+goSomewhere(DX,DY);
	!goSomewhere(DX,DY);
.*/

+step(X) <- !action.

+!action: moves_left(0) <- true. 

+!action: (not carrying_gold(0) | not carrying_wood(0)) & pos(PosX,PosY) & depot(PosX,PosY) <-
	do(drop);
	!action.

+!action: (not carrying_gold(0) | not carrying_wood(0)) & depot(PosX,PosY) & not goSomewhere(_,_) & not moves_left(0) <-
	+goSomewhere(PosX,PosY);
	if(not(substep(_))) { +substep(0); };
	!goSomewhere(PosX,PosY);
	!action.

+!action: pos(PosX, PosY) & gold(PosX, PosY) & carrying_gold(Gold) & carrying_wood(0) &
	carrying_capacity(Cap) & (Gold <= Cap) & ally(PosX, PosY) & not moves_left(0) <-
	do(pick);
	-found(gold,PosX,PosY);
	!action.

+!action: pos(PosX, PosY) & wood(PosX, PosY) & carrying_gold(0) & carrying_wood(Wood) &
	carrying_capacity(Cap) & (Wood <= Cap) & ally(PosX, PosY) & not moves_left(0) <-
	do(pick);
	-found(wood,PosX,PosY);
	!action.

+!action: pos(PosX, PosY) & wood(PosX, PosY) & carrying_gold(0) & carrying_wood(Wood) &
	carrying_capacity(Cap) & (Wood <= Cap) & ally(PosX, PosY) & moves_left(0) <-
	true.

+!action: goSomewhere(DX, DY) & not moves_left(0) <-
	if(not(substep(_))) { +substep(0); };
	!goSomewhere(DX,DY);
	!action.

+!action: not moves_left(0) <-
	.print("Nothing to do!");
	do(skip);
	!action.

+obstacle(X,Y): not(found(obstacle,X,Y)) <-
	+found(obstacle,X,Y);
.

+gold(X,Y): not(found(gold,X,Y)) & friend(F1) & friend(F2) & (F1 \== F2) <-
	+found(gold,X,Y);
	.send(F1, tell, found(gold,X,Y));
	.send(F2, tell, found(gold,X,Y));
.

+wood(X,Y): not(found(wood,X,Y)) & friend(F1) & friend(F2) & (F1 \== F2) <-
	+found(wood,X,Y);
	.send(F1, tell, found(gold,X,Y));
	.send(F2, tell, found(gold,X,Y));
.

+!doMove(Direction): substep(S) & pos(PosX, PosY) & friend(F1) & friend(F2) & (F1 \== F2) & grid_size(GridX, GridY) & visibility(V) <-
	-substep(S); +substep(S + 1);
	.abolish(last_move(_));
	+last_move(Direction);
	do(Direction);
	
	for( .range(CntX,-V,V) ) {
		for( .range(CntY,-V,V) ) {
			if((PosX + CntX >= 0) & (PosY + CntY >= 0) & (PosX + CntX <= GridX) & (PosY + CntY <= GridY)) {
				A = PosX + CntX; B = PosY + CntY;
				+explored(PosX + CntX, PosY + CntY);
				.send(F1, tell, explored(A,B));
				.send(F2, tell, explored(A,B));
			}
		}
	}
.

+!goSomewhere(X,Y): moves_per_round(0) <- true.
@goSomewhere[atomic] +!goSomewhere(X,Y): moves_per_round(N) <-
	!getMovement(X,Y); !goToSpecificPoint(X,Y);
	!goSomewhere(X,Y).

+!getMovement(X,Y): not free & pos(PosX, PosY) & grid_size(GridX, GridY) & substep(Step) <-
	.abolish(can_go(_));
	+was_on(PosX, PosY, Step);
	if (not(obstacle(PosX + 1, PosY)) & ((PosX + 1) < GridX) & not last_move(left))
		{ +can_go(right) }
	if(not(obstacle(PosX - 1, PosY)) & ((PosX - 1) >= 0   ) & not last_move(right))
		{ +can_go(left) } 
	if(not(obstacle(PosX, PosY + 1)) & ((PosY + 1) < GridY) & not last_move(up))
		{ +can_go(down) } 
	if(not(obstacle(PosX, PosY - 1)) & ((PosY - 1) >= 0   ) & not last_move(down))
		{ +can_go(up) } 
.

+!getMovement(X,Y): pos(PosX, PosY) & grid_size(GridX, GridY) & substep(Step) <-
	.abolish(can_go(_));
	+was_on(PosX, PosY, Step);
	if(not(obstacle(PosX + 1, PosY)) & ((PosX + 1) < GridX) & not(was_on(PosX + 1, PosY, _)))
		{ +can_go(right) }
	if(not(obstacle(PosX - 1, PosY)) & ((PosX - 1) >= 0   ) & not(was_on(PosX - 1, PosY, _)))
		{ +can_go(left) } 
	if(not(obstacle(PosX, PosY + 1)) & ((PosY + 1) < GridY) & not(was_on(PosX, PosY + 1, _)))
		{ +can_go(down) } 
	if(not(obstacle(PosX, PosY - 1)) & ((PosY - 1) >= 0   ) & not(was_on(PosX, PosY - 1, _)))
		{ +can_go(up) } 
.                                                           

+!goToSpecificPoint(X,Y): grid_size(GridX, GridY) & substep(NowStep) & pos(PosX,PosY) 
	& was_on(PosX,PosY, PrevStep) & was_on(PosX,PosY, PrevPrevStep) & ((NowStep - PrevStep) > 4) 
	& ((PrevStep - PrevPrevStep) > 4) & ((NowStep - PrevStep) == (PrevStep - PrevPrevStep)) & not(free)  <-
	.print("SHIT");
	//!getMovement(X,Y);
	if(PosX = (GridX - 1)) { !doMove(left); }
	if(PosX = 0) {!doMove(right); }
	if(PosY = (GridY - 1))  { !doMove(up); }
	if(PosY = 0) { !doMove(down); }
	else { +free; !getMovement(X,Y); !goToSpecificPoint(X,Y); }
.
+!goToSpecificPoint(X,Y): moves_left(0) <- true.

+!goToSpecificPoint(X,Y): pos(X, Y) & goSomewhere(X, Y) & grid_size(GridX, GridY) <-
	.print("Done!");
	-goSomewhere(X, Y);
	.abolish(substep(_));
	.abolish(was_on(_,_,_));
	!action.

+!goToSpecificPoint(X,Y) : pos(PosX, PosY) & grid_size(GridX, GridY) & substep(Step) &
	not(can_go(left)) & not(can_go(right)) & not(can_go(up)) & not(can_go(down)) & not(returning(_)) <-
	.abolish(returning(_));
	+returning(Step - 1);
	.print("I AM STUCK");
	!goToSpecificPoint(X,Y);
.

+!goToSpecificPoint(X,Y) : pos(PosX, PosY) & grid_size(GridX, GridY) & returning(BackStep) & substep(NowStep) &
	was_on(GoToX, GoToY, BackStep) & not can_go(left) & not can_go(right) & not can_go(up) & not can_go(down) <-
	
	-substep(NowStep); +substep(NowStep + 1);
	-returning(BackStep); +returning(BackStep - 1);
	if(PosX > GoToX) { !doMove(left); }
	if(PosX < GoToX) { !doMove(right); }
	if(PosY > GoToY) { !doMove(up); }
	if(PosY < GoToY) { !doMove(down); }
.

// ***************  DEFAULT MOVEMENT *****************
// up -> right -> left -> down
// UP + LEFT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY > Y) & last_move(down)  <- -free; .abolish(returning(_)); !moveOrder(left,down,up,right).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY > Y) & last_move(right) <- -free; .abolish(returning(_)); !moveOrder(up,right,left,down).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY > Y)                    <- -free; .abolish(returning(_)); !moveOrder(up,left,right,down).

// DOWN + LEFT	
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY < Y) & last_move(up)    <- -free; .abolish(returning(_)); !moveOrder(left,up,down,right).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY < Y) & last_move(right) <- -free; .abolish(returning(_)); !moveOrder(down,right,left,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY < Y)                    <- -free; .abolish(returning(_)); !moveOrder(down,left,right,up).

// UP + RIGHT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY > Y) & last_move(down)  <- -free; .abolish(returning(_)); !moveOrder(right,down,up,left).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY > Y) & last_move(left)  <- -free; .abolish(returning(_)); !moveOrder(up,left,right,down).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY > Y)                    <- -free; .abolish(returning(_)); !moveOrder(up,right,left,down).

// DOWN + RIGHT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY < Y) & last_move(up)    <- -free; .abolish(returning(_)); !moveOrder(right,up,down,left).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY < Y) & last_move(left)  <- -free; .abolish(returning(_)); !moveOrder(down,left,right,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY < Y)                    <- -free; .abolish(returning(_)); !moveOrder(down,right,left,up).

// UP
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY > Y) & last_move(down)  <- -free; .abolish(returning(_)); !moveOrder(right,left,down,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY > Y) & last_move(left)  <- +free; .abolish(returning(_)); !moveOrder(up,left,down,right).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY > Y) & last_move(right) <- -free; .abolish(returning(_)); !moveOrder(up,right,down,left).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY > Y) 				   <- +free; .abolish(returning(_)); !moveOrder(up,right,left,down).

// DOWN
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY < Y) & last_move(up)    <- -free; .abolish(returning(_)); !moveOrder(right,left,up,down).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY < Y) & last_move(left)  <- -free; .abolish(returning(_)); !moveOrder(down,left,right,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY < Y) & last_move(right) <- -free; .abolish(returning(_)); !moveOrder(down,right,up,left).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY < Y) 				   <- +free; .abolish(returning(_)); !moveOrder(down,left,right,up).

// RIGHT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY = Y) & last_move(left)  <- -free; .abolish(returning(_)); !moveOrder(up,down,left,right).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY = Y) & last_move(up)    <- -free; .abolish(returning(_)); !moveOrder(right,up,left,down).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY = Y) & last_move(down)  <- -free; .abolish(returning(_)); !moveOrder(right,down,left,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY = Y) 				   <- +free; .abolish(returning(_)); !moveOrder(right,up,down,left).

// LEFT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY = Y) & last_move(right) <- -free; .abolish(returning(_)); !moveOrder(up,down,right,left).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY = Y) & last_move(up)    <- -free; .abolish(returning(_)); !moveOrder(left,up,right,down).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY = Y) & last_move(down)  <- -free; .abolish(returning(_)); !moveOrder(left,down,right,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY = Y) 				   <- +free; .abolish(returning(_)); !moveOrder(left,up,down,right).

+!moveOrder(D,_,_,_): can_go(D) <- !doMove(D).
+!moveOrder(_,D,_,_): can_go(D) <- !doMove(D).
+!moveOrder(_,_,D,_): can_go(D) <- !doMove(D).
+!moveOrder(_,_,_,D): can_go(D) <- !doMove(D).
// ------ END -----

+!update_target(X,Y) : goSomewhere(PosX,PosY) & depot(PosX,PosY) <- +nextGoSomewhere(X,Y) ; .print("OK 1 ---------------------------------- ").
+!update_target(X,Y) : goSomewhere(PosX,PosY) <- -goSomewhere(PosX,PosY); +goSomewhere(X,Y); .print("OK 2 ---------------------------------- ").
+!update_target(X,Y) : not goSomewhere(_,_) <- +goSomewhere(X,Y); +free; .print("OK 3 ---------------------------------- ").

