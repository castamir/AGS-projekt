/*
Nove znalosti o prostredi, ktore sa posielaju ostatnym dvom agentom:
explored(X,Y) - agent preskumal pole [X,Y] - videl ho
found(obstacle|gold|wood,X,Y) - na policku [X,Y] je prekazka/zlato/drevo. odosielaju sa zatial len informacie o surovinach

Dalsie znalosti:
substep(X) - step(Y) pocita kola, substep(X) pocita pocet krokov agenta (teda fast ma napr. X = 3*Y) - nutne pre backtracking
was_on(X,Y,Z) - agent sa v podkroku (substep) Z nachadzal na pozicii [X,Y]. Po dokonceni ciela sa tieto informacie zmazu.
can_go(up|right|left|down) - agent sa moze posunut danym smerom - policko je v ramci mriezky a agent na nom este nebol (was_on)
returning(Step) - agent sa od kroku Step vracia naspat po svojich krokoch, podla was_on.
gold(X,Y); wood(X,Y), obstacle(X,Y) - na [X,Y] je zlato/drevo/prekazka
last_move(up|right|left|down) - smer posledneho kroku

Ciele:
!goSomewhere(X,Y) - spojene so znalostou goSomewhere(X,Y): agent ide na poziciu [X,Y]. sklada sa len z cielov getMovement a goToSpecificPoint.
!getMovement(X,Y) - zisti, na ktore policka okolo agenta je mozne prejst pomocou do(Direction) do was_on
!goToSpecificPoint(X,Y) - 
!doMove(Direction) - vykonanie pohybu danym smerom - odporucam pouzivat namiesto do(Dir) - doMove uchovava informacie navyse
!moveOrder(A,B,C,D) - priorita pohybov: ak mozem ist smerom A, idem smerom A. ak nie a ak mozem ist smerom B, idem smerom B...
*/

!start.
+!start : .my_name(Name) & .substring("a",Name,0) <-
	+side("a");
	+last_move(blank);
. 
+!start : .my_name(Name) & .substring("b",Name,0) <-
	+side("b");
	+last_move(blank);
.

+step(0): depot(DX,DY) <- 
	if(not(substep(_))) { +substep(0); }
	+goSomewhere(DX,DY);
	!goSomewhere(DX,DY);
.

+step(X): pos(PosX, PosY) & gold(PosX, PosY) & carrying_gold(Gold) & carrying_wood(Wood) &
	carrying_capacity(Cap) & (Wood = 0) & (Gold <= Cap) & ally(PosX, PosY) <- 
	do(pick);
	-found(gold,PosX,PosY);
.

+step(X): pos(PosX, PosY) & wood(PosX, PosY) & carrying_gold(Gold) & carrying_wood(Wood) &
	carrying_capacity(Cap) & (Wood <= Cap) & (Gold = 0) & ally(PosX, PosY) <- 
	do(pick);
	-found(wood,PosX,PosY);
.

/* Odlozenie surovin v Depote
+step(X): pos(PosX, PosY) & depot(PosX, PosY) & carrying_gold(Gold) & carrying_wood(Wood) &
	((Gold >= 0) | (Wood >= 0)) <- 
	do(drop);
.
*/
/* Zavolanie rychleho agenta: Na pozicii GoX, GoY je surovina, ja tam idem, a dojdi tam aj ty, nech mozeme zobrat surovinu.
Zo zadania:  Pro usp?n? sebr?n? suroviny z dan? pozice mus? b?t na stejn? pozici alespo? jeden sp??telen? agent.
+step(X): carrying_gold(Gold) & carrying_wood(Wood) & ((Gold + Wood) = 0) & friend(F) & ((F = "aFast") | (F = "bFast")) & 
	found(Stuff,GoX,GoY) & pos(PosX, PosY) & ((Stuff = wood) | (Stuff = gold)) & (carrying_capacity \== 2 )<-
	!goSomewhere(GoX,GoY);
	.send(F, achieve, goSomewhere(GoX,GoY));
.
*/
+step(X): goSomewhere(DX, DY) <-
	!goSomewhere(DX,DY);
.

+step(X): moves_left(Moves) <- 
	.print("Nothing to do!");
	if(Moves = 3) { do(skip); do(skip); do(skip); }
	if(Moves = 2) { do(skip); do(skip); }
	if(Moves = 1) { do(skip); } 
.

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

+!doMove(Direction): substep(S) & pos(PosX, PosY) & friend(F1) & friend(F2) & (F1 \== F2)
	& grid_size(GridX, GridY) <-
	-substep(S); +substep(S + 1);
	.abolish(last_move(_));
	+last_move(Direction);
	do(Direction);
	
	if(carrying_capacity > 1) {
		for( .range(CntX,-1,1) ) {
			for( .range(CntY,-1,1) ) {
				if((PosX + CntX >= 0) & (PosY + CntY >= 0) & (PosX + CntX <= GridX) & (PosY + CntY <= GridY)) {
					A = PosX + CntX; B = PosY + CntY;
					+explored(PosX + CntX, PosY + CntY);
					.send(F1, tell, explored(A,B));
					.send(F2, tell, explored(A,B));
				}
			}	
		}
	}
	else {
		for( .range(CntX,-3,3) ) {
			for( .range(CntY,-3,3) ) {
				if((PosX + CntX >= 0) & (PosY + CntY >= 0) & (PosX + CntX <= GridX) & (PosY + CntY <= GridY)) {
					A = PosX + CntX; B = PosY + CntY;
					+explored(PosX + CntX, PosY + CntY);
					.send(F1, tell, explored(A,B));
					.send(F2, tell, explored(A,B));
				}
			}	
		}
	}
.

+!goSomewhere(X,Y): moves_per_round(1) <-
	!getMovement(X,Y); !goToSpecificPoint(X,Y);
.
+!goSomewhere(X,Y): moves_per_round(2) <-
	!getMovement(X,Y); !goToSpecificPoint(X,Y); 
	!getMovement(X,Y); !goToSpecificPoint(X,Y);
.
+!goSomewhere(X,Y): moves_per_round(3) <- 
	!getMovement(X,Y); !goToSpecificPoint(X,Y);
	!getMovement(X,Y); !goToSpecificPoint(X,Y);
	!getMovement(X,Y); !goToSpecificPoint(X,Y);
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

+!goToSpecificPoint(X,Y): pos(PosX, PosY) & grid_size(GridX, GridY) & moves_left(Moves) &
	(PosX = X) & (PosY = Y) <-
	.print("Done!");
	-goSomewhere(GoX, GoY);
	.abolish(was_on(_,_,_));
	if(Moves = 3) { do(skip); do(skip); do(skip); }
	if(Moves = 2) { do(skip); do(skip); }
	if(Moves = 1) { do(skip); } 
. 

+!goToSpecificPoint(X,Y) : pos(PosX, PosY) & grid_size(GridX, GridY) & substep(Step) &
	not(can_go(left)) & not(can_go(right)) & not(can_go(up)) & not(can_go(down)) & not(returning(_)) <-
	.abolish(returning(_));
	+returning(Step - 1);
	.print("I AM STUCK");
	!goToSpecificPoint(X,Y);
.

+!goToSpecificPoint(X,Y) : pos(PosX, PosY) & grid_size(GridX, GridY) & returning(BackStep) & substep(NowStep) &
	was_on(GoToX, GoToY, BackStep) & not(can_go(left)) & not(can_go(right)) & not(can_go(up)) & not(can_go(down)) <-
	
	-substep(NowStep); +substep(NowStep + 1);
	-returning(BackStep); +returning(BackStep - 1);
	if(PosX > GoToX) { !doMove(left); }
	if(PosX < GoToX) { !doMove(right); }
	if(PosY > GoToY) { !doMove(up); }
	if(PosY < GoToY) { !doMove(down); }
.

// ***************  DEFAULT MOVEMENT *****************

// UP + LEFT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & grid_size(GridX, GridY) & last_move(Last) &
	(PosX > X) & (PosY > Y) <-
	.abolish(returning(_));
	
	if(last_move(down)) { !moveOrder(left,down,up,right); }
	else { if(last_move(right)) { !moveOrder(up,right,left,down); }
	else { !moveOrder(up,left,right,down); }
	}
.
// DOWN + LEFT	
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & grid_size(GridX, GridY) & last_move(Last) &
	(PosX > X) & (PosY < Y) <-
	.abolish(returning(_));
	
	if(last_move(right)) { !moveOrder(left,up,down,right); }
	else { if(last_move(up)) { !moveOrder(down,right,left,up); }
	else { !moveOrder(down,left,right,up); }
	}
.
// UP + RIGHT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & grid_size(GridX, GridY) & last_move(Last) &
	(PosX < X) & (PosY > Y)  <-
	.abolish(returning(_));
	
	if(last_move(down)) { !moveOrder(right,down,up,left); }
	else { if(last_move(left)) { !moveOrder(up,left,right,down); }
	else { !moveOrder(up,right,left,down); }
	}
.
// DOWN + RIGHT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & grid_size(GridX, GridY) & last_move(Last) &
	(PosX < X) & (PosY < Y) <-
	.abolish(returning(_));
	 
	if(last_move(up)) { !moveOrder(right,up,down,left); }
	else { if(last_move(right)) { !moveOrder(down,left,right,up); }
	else { !moveOrder(down,right,left,up); }
	}
.

+!goToSpecificPoint(X,Y): pos(PosX, PosY) & grid_size(GridX, GridY) & last_move(Last) &
	(PosX = X) <-
	.abolish(returning(_));
	
	if(PosY < Y) {
		!moveOrder(down,left,up,right);
	}
	if(PosY > Y) {
		!moveOrder(up,right,down,left);
	}
.

+!goToSpecificPoint(X,Y): pos(PosX, PosY) & grid_size(GridX, GridY) & last_move(Last) &
	(PosY = Y) <-
	.abolish(returning(_));
	
	if(PosX < X) {
		!moveOrder(right,down,left,up);
	}
	if(PosX > X) {
		!moveOrder(left,up,right,down);
	}
.

+!moveOrder(A,B,C,D) <-
	if(can_go(A)) { !doMove(A); }
	else { if(can_go(B)) { !doMove(B); }
	else { if(can_go(C)) { !doMove(C); }
	else { if(can_go(D)) { !doMove(D); }}}}
.
// ------ END -----


