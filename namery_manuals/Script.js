
// ÉÅÉjÉÖÅ[êÿÇËë÷Ç¶
ns6_index=0

function change(e){
  if (!document.all&&!document.getElementById)
    return
  if (!document.all&&document.getElementById)
    ns6_index=1

  var source=document.getElementById&&!document.all? e.target:event.srcElement

  if (source.className=="folding"){
    var source2=document.getElementById&&!document.all? source.parentNode.childNodes:source.parentElement.all
    if (source2[2+ns6_index].style.display=="none"){
      source2[0].src="images/m_DownMenuB.gif"
      source2[2+ns6_index].style.display=''
    }
    else{
      source2[0].src="images/m_DownMenu.gif"
      source2[2+ns6_index].style.display="none"
    }
  }
}

document.onclick=change

