data segment
    zone db 20,0, 20 dup(?)
    op1 dw 0
    op2 dw 0
    op db 0
    tr dw 0
    result dw 0 
    eror dw 0ah,0dh,0ah,0dh,"L'un des nombres decimal n'est pas valide sur 16 bit !$"
    aff dw 0ah,0dh,0ah,0dh,"Le resultat = $"
    grand dw 0ah,0dh,0ah,0dh,"Le resultat est trop grand $" 
    acceuil dw 0ah,0dh,0ah,0dh,"Entrer l'expression a calculer : ",0ah,0dh,0ah,0dh,"$" 
    errz dw 0ah,0dh,0ah,0dh,"On en peut pas diviser par zero !$"
    decimal db 8 dup(?) 
    presentation dw  0ah,0dh,6 dup(20h),"TP2 Assembleur",0ah,0dh,0ah,0dh,4 dup(20h),"Calculatrice classique",0ah,0dh,0ah,0dh,"Auteurs : Boudis mohamed abdelmdjid / Yahioaui Ahmed$"
    finprog dw 0ah,0dh,0ah,0dh,"Fin du programme",0ah,0dh,"$"
ends

stack segment
    dw   128  dup(0)
ends

code segment
;procedure qui lit l'operande
lire proc
  debut: 
    mov di,0    
    mov cx,000ah      
  casparticulier: 
    cmp zone[si],0dh
    je erreur 
    cmp zone[si],20h
    je espace
    mov ax,0
    cmp zone[si],2dh
    je negatif
    cmp zone[si],2bh
    je positif   
  boucle:       ; boucle principale de lecture
    cmp zone[si],0dh ; si entree alors fin    
    je flect  
    mov bl,zone[si] 
    sub bl,30h
    cmp bl,9h
    jg flect
    cmp bl,0h
    jl flect
    mov bh,0
    mul cx 
    inc si    
    add ax,bx
    js verif
    jmp boucle    
  flect:   ;fin de lecture
    cmp zone[si-1],39h ;verifie le cas de deux operation 
    jg erreur
    cmp zone[si-1],30h
    jl erreur
    cmp di,0FFh
    jz nega
    cmp ax,8000h
    je erreur
    jmp suite
  verif:  
    cmp ax,8000h ;verif de -32768
    je flect 
  erreur: 
    mov ah,9  
    lea dx,eror 
    int 33  
    jmp start
  negatif:   ;si le resultat est negatif 
    mov di,0FFh
    inc si 
    cmp zone[si],0dh
    je erreur
    jmp boucle
  nega:
    neg ax     
  suite:   ;mettre a jour la variable
    mov di,sp
    mov di,ss:[di+2]
    mov [di],ax 
    ret
  positif:  ; cas + avant l'operande
    inc si
    cmp zone[si],0dh
    je erreur 
    jmp boucle 
  espace:
    inc si
    jmp casparticulier
endp
; procedure qui execute les operations
exe proc
    cmp op,43
    je plus 
    cmp op,45
    je moin  
    cmp op,42
    je mult
    cmp op,120
    je mult   
    cmp op,47
    je divi    
    jmp erreur 
   plus:
    mov ax,op1
    add ax,op2
    jmp res  
   moin:
    mov ax,op1
    sub ax,op2 
    jmp res 
   mult: 
    mov ax,op1
    imul op2 
    jmp res 
   divi: 
    mov ax,op1
    cwd
    cmp op2,0
    je erreurz
    idiv op2             
   res:
    mov result,ax  
    ret
   erreurz: ;cas division par zero
    mov ah,9
    lea dx,errz
    int 33
    jmp dbt    ; rexecussion de calcul sachant que son addresse de retour est dans tr
endp    
;procedure qui analyse l'expression (module principale)     
calcul proc 
      pop tr ;enregistrer l'adresse de la procedure pour le retour
     dbt:
      mov ah,9
      lea dx,acceuil
      int 33
      mov ah,10
      lea dx,zone
      int 33
      mov si,2
      lea cx,op1
      push cx
      call lire  ;lecture de la premiere operande 
     lap:     ;boucle de lecture d'operande et d'operation
      mov bh,zone[si] 
      mov op,bh
      cmp op,0dh
      je fin2
      inc si
      lea cx,op2
      push cx   ;empilement de l'adresse de l'operande
      call lire  ;lecture de la deuxieme operande 
      call exe    ;execussion de l'operation
      jo debordement
      mov ax,result
      mov op1,ax  ;mettre a jour l'operande 1 au resultat de l'operation precedente
      jmp lap      
     fin2:  
      mov ax,op1
      mov result,ax
      push tr          
      ret
     debordement: ;cas de resultat de plus de 16bits signe 
      mov ah,9 
      lea dx, grand
      int 33
      jmp dbt        
endp
; proceduer pour ecrire le resultat
ecrire Proc
    mov si,7 
    cmp result,0h
    jl negate
   return:
    mov cx,2710h
    mov bx,000ah
    mov ah,9
    lea dx,aff
    int 33
    mov ax,result
    cmp ax,0
    je zero  
   bouc:    ;boucle principale pour mettre le resultat 
    dec si
    mov dx,0000h
    div bx 
    cmp ax,result
    je next
    mov decimal[si],dl
    add decimal[si],30h
   next:
    cmp ax,0000h
    je sortie
    jmp bouc
   negate:
     neg result
     mov di,1h
     jmp return
   signe:  ;enregistrement du signe
    dec si
    mov decimal[si],2dh
    jmp fin:    
   sortie:
    cmp di,1h
    je signe 
    neg result
   fin:
    mov decimal[7],24h  
   show:  ; l'affichage
    mov ah,9
    lea dx,decimal[si]
    int 33  
    neg result
    ret 
   zero:  ; cas de zero
    dec si
    mov decimal[si],30h 
    jmp fin

endp  

start:
    mov ax, data
    mov ds, ax
    mov es, ax  
    
    mov ah,9     ;affichage d'acceuil
    lea dx,presentation
    int 33
         
    call calcul ;analyse de l'expression
    call ecrire ;ecriture du resultat
    
    mov ah,9      ; affichage de fin de programme
    lea dx,finprog
    int 33
                 
    mov ax, 4c00h 
    int 21h    
ends
end start 
