function select_rect_area(main_figure,func)

map_tab_comp=getappdata(main_figure,'Map_tab');
ah=map_tab_comp.map_axes;
x_lim=get(ah,'xlim');
y_lim=get(ah,'ylim');

cp = ah.CurrentPoint;
xinit = cp(1,1);
yinit = cp(1,2);

if xinit<x_lim(1)||xinit>x_lim(end)||yinit<y_lim(1)||yinit>y_lim(end)
    return;
end

u=1;


x_box=xinit;
y_box=yinit;


hp=line(ah,x_box,y_box,'color','r','linewidth',1,'Tag','reg_temp');


replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb);
replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);


    function wbmcb(~,~)
        cp = ah.CurrentPoint;
        
        u=u+1;
        

        X = [xinit,cp(1,1)];
        Y = [yinit,cp(1,2)];
                
        x_min=nanmin(X);
     
        x_max=nanmax(X);
         
        y_min=nanmin(Y);
         
        y_max=nanmax(Y);
        
        x_box=([x_min x_max  x_max x_min x_min]);
        y_box=([y_max y_max y_min y_min y_max]);
        

        if isvalid(hp)
            set(hp,'XData',x_box,'YData',y_box,'Tag','reg_temp');
        else
            hp=plot(ah,x_box,x_box,'color','k','linewidth',1);
        end
        

        
    end

    function wbucb(main_figure,~)
        
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2);
        
        if isempty(y_box)||isempty(x_box)
            delete(txt);
            delete(hp);
            return;
        end
        
        y_min=nanmin(y_box);
        y_max=nanmax(y_box);
        
        x_min=nanmin(x_box);
        
        x_max=nanmax(x_box);

        delete(hp);
        
        feval(func,main_figure,[x_min x_max],[y_min y_max]);
                
    end



end