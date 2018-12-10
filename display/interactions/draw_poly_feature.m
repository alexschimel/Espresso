
%% Function
function draw_poly_feature(src,evt,main_figure)

disp_config=getappdata(main_figure,'disp_config');

map_tab_comp = getappdata(main_figure,'Map_tab');

ah=map_tab_comp.map_axes;


features_h=findobj(ah,{'tag','feature_temp'});
delete(features_h);
features_h=findobj(ah,{'tag','reg_tmp'});
delete(features_h);

switch main_figure.SelectionType
    case 'normal'
        
    otherwise

        return;
end

cp = ah.CurrentPoint;

xinit=nan(1,1e4);
yinit=nan(1,1e4);
xinit(1) = cp(1,1);
yinit(1)=cp(1,2);

u=2;

x_lim=get(ah,'xlim');
y_lim=get(ah,'ylim');

if xinit(1)<x_lim(1)||xinit(1)>x_lim(end)||yinit(1)<y_lim(1)||yinit(1)>y_lim(end)
    return;
end

col_line='r';
hp=plot(ah,xinit,yinit,'color',col_line,'linewidth',1,'Tag','feature_temp');
txt=text(ah,cp(1,1),cp(1,2),sprintf('%.2f m',cp(1,2)),'color',col_line,'Tag','feature_temp');

replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb_ext);
replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',@wbdcb_ext);

   function wbmcb_ext(~,~)
       
        cp=ah.CurrentPoint;
        xinit(u)=cp(1,1);
        yinit(u)=cp(1,2);

        
        if isvalid(hp)
            set(hp,'XData',xinit,'YData',yinit);
        else
            hp=plot(ah,xinit,yinit,'color',col_line,'linewidth',1,'Tag','feature_temp');
        end
        
        if isvalid(txt)
            set(txt,'position',[cp(1,1) cp(1,2) 0],'string',sprintf('(%.2f,%.2f)',cp(2,1),cp(1,2)));
        else
            txt=text(ah,cp(1,1),cp(1,2),sprintf('%.2f m',cp(1,2)),'color',col_line,'Tag','feature_temp');
        end
   end

    function wbdcb_ext(~,~)
        
        switch main_figure.SelectionType
            case {'open' 'alt'}

                wbucb(main_figure,[]);
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@draw_poly_feature,main_figure});
                return;
        end
        
        check_xy();
        u=length(xinit)+1;
        
        if isvalid(hp)
            set(hp,'XData',xinit,'YData',yinit);
        else
            hp=plot(ah,xinit,yinit,'color',col_line,'linewidth',1,'Tag','feature_temp');
        end
        
        
    end

    function check_xy()
        xinit(isnan(xinit))=[];
        yinit(isnan(yinit))=[];
        x_rem=xinit>x_lim(end)|xinit<x_lim(1);
        y_rem=yinit>y_lim(end)|yinit<y_lim(1);

        xinit(x_rem|y_rem)=[];
        yinit(x_rem|y_rem)=[];
        
%         [x_f,IA,~] = unique(xinit);
%         y_f=yinit(IA);
    end

    function wbucb(main_figure,~)
        
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        

        xinit(isnan(xinit))=[];
        yinit(isnan(yinit))=[];
        xinit(xinit>x_lim(end))=x_lim(end);
        xinit(xinit<x_lim(1))=x_lim(1);
        
        yinit(yinit>y_lim(end))=y_lim(end);
        yinit(yinit<y_lim(1))=y_lim(1);
       
        
        delete(txt);
        delete(hp);
        
        if length(yinit)<=2
            return;
        end


        %feval(func,main_figure,poly_r,poly_pings);
        features=getappdata(main_figure,'features');
        poly=polyshape(xinit,yinit);
        new_feature=feature_cl('Polygon',poly,'Projection',disp_config.MET_tmproj);
        if isempty(features)
            features=new_feature;
        else
            features=[features new_feature];
        end
        setappdata(main_figure,'features',features);
        display_features(main_figure,new_feature.Unique_ID);
        
    end

    
end
