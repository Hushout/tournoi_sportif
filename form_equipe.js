$( document ).ready(function() {
    const dicCodeMSG={
        "0": {'text':"Cette équipe est déjà inscrit dans ce tournoi",'class':"error"},
        "1": {'text':"L'équipe a bien été ajouté",'class':"succes"},
        "2": {'text':"Un problàme s'est prooduit",'class':"error"}
    };
    const urlParams = new URLSearchParams(window.location.search);
    const idTournoi = urlParams.get('id');  //
    const codeMSG = urlParams.get('codeMSG'); 

    if(idTournoi==null){
        window.location="page_home.php";
    }
    myAjax('getNbJoueurByIdTournoi',{'id' : idTournoi},(data)=>{
        if(! data){
            $('body').append(`
                <h2>Ce tournoi n'existe plus :(</h2>
                <br>
                <a href="javascript:window.open('','_self').close();"><button>revenir vers la page d'accueil</button></a>    
            `);
            return;
        }
        optionNiveau=`<option value="">-- Choisissez un niveau --</option>`;
        $.each(listNiveau,(index,niveau)=>{
            optionNiveau+=`<option value="${niveau}">${niveau}</option>`;
        });
        
        NbJoueur=data["NbJoueur"];
        // console.log(NbJoueur);
            html=`<h3 class="text-center" >Formulaire d'Equipe</h3>
                <form action="ajout_equipe.php" method="post" id="formId">
                    <input type="hidden" name="idTournoi" id="idTournoi" value="${idTournoi}">
                    <label for="nomEquipe">Nom de l'équipe : </label>
                    <input type="text" id="nomEquipe" placeholder="nomEquipe" autocomplete="off" name="nomEquipe" required><br>
                    <label for="nomClub">Le nom de votre club (si vous en avez un):</label>
                    <input type="text" id="nomClub" placeholder="nomClub" autocomplete="off" name="nomClub"><br>
                    <h3 class="text-center" >Ajoutez les joueurs</h3>
            `;
            for (var i =1; i <= NbJoueur; i++){
                html+=`
                    <h5 class="text-center" >Remplissez les infos sur le joueurs n°`+i+`</h5>
                    <label for="nomJoueur`+i+`">Nom:</label>
                    <input type="text" name="nomJoueur`+i+`" required><br>
                    <label for="prenomJoueur`+i+`">Prenom</label>
                    <input type="text" name="prenomJoueur`+i+`" required><br>
                    <label for="nvJoueur`+i+`">Niveau du joueur</label>
                    
                    <select name="nvJoueur`+i+`" required>
                    ${optionNiveau}
                    </select><br>
                `; 
                //label+input pour joueur /concatiner le iavec 
                //joueurdans name de input/niveau c'est un input select
            }
            html+=`<button type="submit" form="formId" value="Submit">Finir Formulaire</button>`;
            if(codeMSG!=null){
                html+=`
                    <br><span class='${dicCodeMSG[codeMSG]['class']}'>*${dicCodeMSG[codeMSG]['text']}</span>
                `;
            }
            html+=`
            </form>
            <br>
            <a href="javascript:window.open('','_self').close();"><button>revenir vers la page d'accueil</button></a>

            `;
    $('body').append(html);
    
    

    });  

});

function myAjax(nomFonction,params,successFonction){
    params['__x__']=0;
    $.ajax({
        url: 'functions.php',
        type: 'POST',
        dataType:'json',
        data: {
            'function':nomFonction,
            'params':params
        },
        success: successFonction,
        error: printError
    });
}

function printError(error){    //afficher la page d'erreur 
		
    console.error("status: "+error['status']+"\nstatusText: "+error['statusText']);
    $('body').replaceWith(error['responseText']);
    
}
