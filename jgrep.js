$(document).ready(function()
{
    var urlitems=window.location.href.split("#");
    var curpage=urlitems[1];
    if(!(curpage==null)){
        $.ajax({
            url: curpage + ".html",
            cache: false,
            success: function(html){
                $("#container").replaceWith(html);
            }
        });
    }
    else{
        $.ajax({
            url: "home.html",
            cache: false,
            success: function(html){
                $("#container").replaceWith(html);
            }
        });
    }

    $(".menu-item").hover(function(e)
    {
        $(e.currentTarget).css("background-color","#434343");
        $(this).css('cursor', 'pointer');
    });

    $(".menu-item").mouseout(function(e)
    {
        $(e.currentTarget).css("background-color", "#000000");
    });

    $(".menu-item").click(function(e)
    {
        if(e.currentTarget.id == "menu-documentation"){
            $(location).attr("href", "http://rubydoc.info/gems/jgrep/1.3.0/frames")
        }
        else if(e.currentTarget.id == "menu-issues"){
            $(location).attr("href", "https://github.com/ploubser/JSON-Grep/issues")
        }
        else{
            $.ajax({
                url: e.currentTarget.id.replace("menu-", "") + ".html",
                cache: false,
                success: function(html){
                    $("#container").replaceWith(html);
                    window.location.href = "#" + e.currentTarget.id.replace("menu-", "");
                    $(document.body).scrollTop(0);

                }
            });
        }
    });
});
