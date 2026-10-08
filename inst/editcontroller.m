## 16.06.2016 Erivelton Gualter dos Santos <erivelton.gualter@gmail.com>
## editcontroller
## GSoC 2018: https://eriveltongualter.github.io/GSoC2018/
## Author: Erivelton Gualter dos Santos <erivelton.gualter@gmail.com>

graphics_toolkit qt

global h1 h3 fig3

if isempty(fig3) || !ishandle(fig3)
  fig3 = figure(3);
endif

set(0, 'currentfigure', fig3);

h3.sys = h1.C;

[~, ~, k, ~] = getZP (h3.sys);
t = h3.sys/k;
T = evalc('t'); idx = find(T == "y", 1, 'last'); T(idx:idx+2) = "x  ";

h3.zpk_idx = [];
maxn = 15;
h3.zpk = zeros(1, maxn);
h3.location = zeros(1, maxn);
h3.damp = zeros(1, maxn);
h3.freq = zeros(1, maxn);
h3.currentzpk = [];

## Callbacks Menu

function call_select(src, evt)
  global h1 h3 fig3
  if ishandle(fig3)
    set(0, 'currentfigure', fig3);
  endif

  switch ( get (h3.select_compensator, "Value") )
      case {1}
        h3.sys = h1.C;
      case {2}
        h3.sys = h1.F;
  endswitch
  h3.currentzpk = [];
  dynamics();
endfunction

function update_active_sys()
  global h1 h3
  if isfield(h3, 'select_compensator') && ishandle(h3.select_compensator)
    if get(h3.select_compensator, "Value") == 2
      h1.F = h3.sys;
    else
      h1.C = h3.sys;
    endif
  else
    h1.C = h3.sys;
  endif
endfunction

function dynamics(varargin)
  global h1 h3 fig3

  if ishandle(fig3)
    set(0, 'currentfigure', fig3);
  endif

  % Delete old panel if it exists to prevent Qt crash
  if isfield(h3, 'p2') && ishandle(h3.p2)
    delete(h3.p2);
  endif

  % Re-create UI panel for dynamics list
  h3.p2 = uipanel ("parent", fig3, "title", "Dynamics", "position", [.05 .05 .43 .7]);

  uicontrol ("parent", h3.p2, "style", "text", "units", "normalized", "string", "Type", "fontweight", "bold", "horizontalalignment", "left", "position", [0.05 0.83 .25 .1]);
  uicontrol ("parent", h3.p2, "style", "text", "units", "normalized", "string", "Location", "fontweight", "bold", "horizontalalignment", "center", "position", [0.25 0.83 .25 .1]);
  uicontrol ("parent", h3.p2, "style", "text", "units", "normalized", "string", "Damping", "fontweight", "bold", "horizontalalignment", "center", "position", [0.50 0.83 .25 .1]);
  uicontrol ("parent", h3.p2, "style", "text", "units", "normalized", "string", "Frequency", "fontweight", "bold", "horizontalalignment", "center", "position", [0.75 0.83 .25 .1]);

  [olpol, olzer, k, ~] = getZP (h3.sys);
  if isfield(h3, 'gain_box') && ishandle(h3.gain_box)
    set(h3.gain_box, "String", num2str(k));
  endif

  np = length(olpol);
  nz = length(olzer);
  N = np + nz;

  % Validate index
  if isempty(h3.currentzpk) || h3.currentzpk > N || h3.currentzpk < 1
    h3.currentzpk = [];
  endif

  for i = 1:N
    yPos = 0.8 - 0.07 * i;

    % Determine initial radio state
    is_selected = (!isempty(h3.currentzpk) && h3.currentzpk == i);

    if i <= np
      % Poles
      if imag(olpol(i)) ~= 0
        h3.zpk(i) = uicontrol ("parent", h3.p2, "style", "radiobutton", "units", "normalized", "string", "Complex Pole", "value", is_selected, "callback", @(src, evt) select_dynamic(i), "horizontalalignment", "left", "position", [0 yPos .25 .07]);
        h3.freq(i) = uicontrol ("parent", h3.p2, "style", "text", "units", "normalized", "string", num2str(abs(olpol(i))), "horizontalalignment", "center", "position", [0.75 yPos .25 .07]);
        h3.damp(i) = uicontrol ("parent", h3.p2, "style", "text", "units", "normalized", "string", num2str(cos(angle(olpol(i)))), "horizontalalignment", "center", "position", [0.5 yPos .25 .07]);
      else
        h3.zpk(i) = uicontrol ("parent", h3.p2, "style", "radiobutton", "units", "normalized", "string", "Real Pole", "value", is_selected, "callback", @(src, evt) select_dynamic(i), "horizontalalignment", "left", "position", [0 yPos .25 .07]);
        h3.freq(i) = uicontrol ("parent", h3.p2, "style", "text", "units", "normalized", "string", num2str(abs(olpol(i))), "horizontalalignment", "center", "position", [0.75 yPos .25 .07]);
        h3.damp(i) = uicontrol ("parent", h3.p2, "style", "text", "units", "normalized", "string", "1", "horizontalalignment", "center", "position", [0.5 yPos .25 .07]);
      endif
      h3.location(i) = uicontrol ("parent", h3.p2, "style", "text", "units", "normalized", "string", num2str(olpol(i)), "horizontalalignment", "center", "position", [.25 yPos .25 .07]);
      h3.real(i) = real(olpol(i));
      h3.imag(i) = imag(olpol(i));
    else
      % Zeros
      idx_z = i - np;
      if imag(olzer(idx_z)) ~= 0
        h3.zpk(i) = uicontrol ("parent", h3.p2, "style", "radiobutton", "units", "normalized", "string", "Complex Zero", "value", is_selected, "callback", @(src, evt) select_dynamic(i), "horizontalalignment", "left", "position", [0 yPos .25 .07]);
        h3.freq(i) = uicontrol ("parent", h3.p2, "style", "text", "units", "normalized", "string", num2str(abs(olzer(idx_z))), "horizontalalignment", "center", "position", [0.75 yPos .25 .07]);
        h3.damp(i) = uicontrol ("parent", h3.p2, "style", "text", "units", "normalized", "string", num2str(cos(angle(olzer(idx_z)))), "horizontalalignment", "center", "position", [0.5 yPos .25 .07]);
      else
        h3.zpk(i) = uicontrol ("parent", h3.p2, "style", "radiobutton", "units", "normalized", "string", "Real Zero", "value", is_selected, "callback", @(src, evt) select_dynamic(i), "horizontalalignment", "left", "position", [0 yPos .25 .07]);
        h3.freq(i) = uicontrol ("parent", h3.p2, "style", "text", "units", "normalized", "string", num2str(abs(olzer(idx_z))), "horizontalalignment", "center", "position", [0.75 yPos .25 .07]);
        h3.damp(i) = uicontrol ("parent", h3.p2, "style", "text", "units", "normalized", "string", "1", "horizontalalignment", "center", "position", [0.5 yPos .25 .07]);
      endif
      h3.location(i) = uicontrol ("parent", h3.p2, "style", "text", "units", "normalized", "string", num2str(olzer(idx_z)), "horizontalalignment", "center", "position", [.25 yPos .25 .07]);
      h3.real(i) = real(olzer(idx_z));
      h3.imag(i) = imag(olzer(idx_z));
    endif
  endfor

  % Show Transfer function
  [~, ~, k, ~] = getZP (h3.sys);
  t = h3.sys/k;
  T = evalc('t'); idx = find(T == "y", 1, 'last'); T(idx:idx+2) = "x  ";
  h3.lbl_num = uicontrol ("style", "text", "units", "normalized", "string", T(55:end-24), "horizontalalignment", "left", "verticalalignment", "middle", "position", [.62 .8 .3 .18]);

  % Render edit controls for selected item
  plot_edit_dynamics();
  drawnow();
endfunction

function select_dynamic(idx)
  global h3
  [olpol, olzer, ~, ~] = getZP (h3.sys);
  N = length(olpol) + length(olzer);

  % Toggle selected state across radio buttons
  h3.currentzpk = idx;
  for k = 1:N
    if k == idx
      set(h3.zpk(k), "Value", 1);
    else
      set(h3.zpk(k), "Value", 0);
    endif
  endfor

  plot_edit_dynamics();
endfunction

function plot_edit_dynamics(varargin)
  global h3 fig3
  if ishandle(fig3)
    set(0, 'currentfigure', fig3);
  endif

  if isfield(h3, 'p3') && ishandle(h3.p3)
    delete(h3.p3);
  endif

  h3.p3 = uipanel ("parent", fig3, "title", "Edit Select Dynamics", "position", [.52 .05 .43 .7]);

  if isempty(h3.currentzpk)
    uicontrol ("parent", h3.p3, "style", "text", "units", "normalized", "string", "Select a single row to edit values", "horizontalalignment", "center", "position", [0.1 0.45 .8 .1]);
    return;
  endif

  i = h3.currentzpk;
  str1 = get(h3.zpk(i), "string");

  if strcmp(str1, "Complex Pole") || strcmp(str1, "Complex Zero")
    zpk_cfreq = get(h3.freq(i), "String");
    zpk_cdamp = get(h3.damp(i), "String");
    zpk_crpart = num2str(h3.real(i));
    zpk_cipart = num2str(h3.imag(i));

    uicontrol ("parent", h3.p3, "style", "text", "units", "normalized", "string", "Natural Frequency", "horizontalalignment", "left", "position", [0.1 0.65 .35 .08]);
    uicontrol ("parent", h3.p3, "style", "text", "units", "normalized", "string", "Damping", "horizontalalignment", "left", "position", [0.1 0.50 .35 .08]);
    uicontrol ("parent", h3.p3, "style", "text", "units", "normalized", "string", "Real Part", "horizontalalignment", "left", "position", [0.1 0.35 .35 .08]);
    uicontrol ("parent", h3.p3, "style", "text", "units", "normalized", "string", "Imaginary Part", "horizontalalignment", "left", "position", [0.1 0.20 .35 .08]);

    h3.enter_cfreq = uicontrol ("parent", h3.p3, "style", "edit", "units", "normalized", "string", zpk_cfreq, "callback", @call_update_dynamic, "position", [0.55 0.65 .35 0.08], 'backgroundcolor', 'white');
    h3.enter_cdamp = uicontrol ("parent", h3.p3, "style", "edit", "units", "normalized", "string", zpk_cdamp, "callback", @call_update_dynamic, "position", [0.55 0.50 .35 0.08], 'backgroundcolor', 'white');
    h3.enter_crpart = uicontrol ("parent", h3.p3, "style", "edit", "units", "normalized", "string", zpk_crpart, "callback", @call_update_dynamic, "position", [0.55 0.35 .35 0.08], 'backgroundcolor', 'white');
    h3.enter_cipart = uicontrol ("parent", h3.p3, "style", "edit", "units", "normalized", "string", zpk_cipart, "callback", @call_update_dynamic, "position", [0.55 0.20 .35 0.08], 'backgroundcolor', 'white');
  else
    uicontrol ("parent", h3.p3, "style", "text", "units", "normalized", "string", "Location", "horizontalalignment", "left", "position", [0.1 0.45 .35 .08]);
    h3.enter_rlocation = uicontrol ("parent", h3.p3, "style", "edit", "units", "normalized", "string", get(h3.location(i), "String"), "callback", @call_update_dynamic, "position", [0.55 0.45 .35 0.08], 'backgroundcolor', 'white');
  endif
endfunction

function refresh_main_plots()
  global h1 h2 h3

  if isfield(h2, 'axrl') && isaxes(h2.axrl)
    axes(h2.axrl);
    plotrlocus();
  endif

  if isfield(h2, 'axny') && isaxes(h2.axny)
    axes(h2.axny);
    nyquist(h1.G * h1.C);
  endif

  if isfield(h2, 'axbm') && isaxes(h2.axbm)
    axes(h2.axbm);
    plotbode();
  endif

  if isfield(h1, 'ax1') && isaxes(h1.ax1)
    set(0, 'currentfigure', 1);
    axes(h1.ax1);
    plots();
  endif
endfunction

function [olpol, olzer, k, flag] = getZP (sys)
  [num, den] = tfdata (sys, "vector");
  lnum = length (num);
  lden = length (den);

  flag = 0;
  if (lden < 2)
    flag = 0;
  elseif (lnum < lden)
    num = [zeros(1,lden-lnum), num];
    flag = 1;
  endif

  olpol = roots (den);
  olzer = roots (num);
  [~,~,k] = zpkdata(sys);
endfunction

function call_update_gain(src, evt)
  global h1 h2 h3

  [z, p, ~] = zpkdata(h3.sys);
  k = get(h3.gain_box, "String");

  h3.sys = zpk(z, p, str2num(k));
  update_active_sys();

  dynamics();
  refresh_main_plots();
endfunction

function call_update_dynamic(src, evt)
  global h1 h2 h3

  [olpol, olzer, k, ~] = getZP (h3.sys);

  np = length(olpol);
  nz = length(olzer);
  ii = h3.currentzpk;

  if isempty(ii)
    return;
  endif

  imag_flag = 0;
  if np > 0 && ii <= np
    if imag(olpol(ii)) ~= 0
      imag_flag = 1;
    else
      olpol(ii) = str2num(get(h3.enter_rlocation, "String"));
    endif
  endif

  if nz > 0 && ii > np
    if imag(olzer(ii-np)) ~= 0
      imag_flag = 1;
    else
      olzer(ii-np) = str2num(get(h3.enter_rlocation, "String"));
    endif
  endif

  if (imag_flag)
    c(1) = str2num(get(h3.enter_crpart, "String"));
    c(2) = str2num(get(h3.enter_cipart, "String"));

    target_imag = h3.imag(ii);

    for idx = 1:length(olpol)
      if abs(imag(olpol(idx)) - target_imag) < 1e-5
        olpol(idx) = c(1) + 1i * c(2);
      elseif abs(imag(olpol(idx)) + target_imag) < 1e-5
        olpol(idx) = c(1) - 1i * c(2);
      endif
    endfor

    for idx = 1:length(olzer)
      if abs(imag(olzer(idx)) - target_imag) < 1e-5
        olzer(idx) = c(1) + 1i * c(2);
      elseif abs(imag(olzer(idx)) + target_imag) < 1e-5
        olzer(idx) = c(1) - 1i * c(2);
      endif
    endfor
  endif

  h3.sys = zpk (olzer(:), olpol(:), k);
  update_active_sys();

  dynamics();
  refresh_main_plots();
endfunction

function add_rpole(src, evt)
  global h1 h3
  [olpol, olzer, k, ~] = getZP (h3.sys);
  c = -1;
  olpol = [olpol(:); c(1)];
  h3.sys = zpk (olzer(:), olpol, k);
  update_active_sys();
  dynamics();
  refresh_main_plots();
endfunction

function add_cpole(src, evt)
  global h1 h3
  [olpol, olzer, k, ~] = getZP (h3.sys);
  c = [-1 -1];
  olpol = [olpol(:); c(1)+1i*c(2); c(1)-1i*c(2)];
  h3.sys = zpk (olzer(:), olpol, k);
  update_active_sys();
  dynamics();
  refresh_main_plots();
endfunction

function add_rzero(src, evt)
  global h1 h3
  [olpol, olzer, k, ~] = getZP (h3.sys);
  c = -1;
  olzer = [olzer(:); c(1)];
  h3.sys = zpk (olzer, olpol(:), k);
  update_active_sys();
  dynamics();
  refresh_main_plots();
endfunction

function add_czero(src, evt)
  global h1 h3
  [olpol, olzer, k, ~] = getZP (h3.sys);
  c = [-1 -1];
  olzer = [olzer(:); c(1)+1i*c(2); c(1)-1i*c(2)];
  h3.sys = zpk (olzer, olpol(:), k);
  update_active_sys();
  dynamics();
  refresh_main_plots();
endfunction

function add_integrator(src, evt)
  global h1 h3
  [olpol, olzer, k, ~] = getZP (h3.sys);
  olpol = [olpol(:); 0];
  h3.sys = zpk (olzer(:), olpol, k);
  update_active_sys();
  dynamics();
  refresh_main_plots();
endfunction

function add_differentiator(src, evt)
  global h1 h3
  [olpol, olzer, k, ~] = getZP (h3.sys);
  olzer = [olzer(:); 0];
  h3.sys = zpk (olzer, olpol(:), k);
  update_active_sys();
  dynamics();
  refresh_main_plots();
endfunction

function add_pending(src, evt)
  disp('Pending feature');
endfunction

function delete_pz(src, evt)
  global h1 h3 fig3
  if ishandle(fig3)
    set(0, 'currentfigure', fig3);
  endif

  [olpol, olzer, k, ~] = getZP (h3.sys);
  poles(1,:) = [real(olpol)' real(olzer)'];
  poles(2,:) = [imag(olpol)' imag(olzer)'];

  idx = h3.currentzpk;
  if isempty(idx)
    return;
  endif

  if abs(poles(2, idx)) > 0
    idxc = find(poles(2,:) == -1*poles(2, idx), 1, 'last');
    poles(:, idx) = [];
    poles(:, idxc) = [];
    lastpol = length(olpol);
    if idx <= length(olpol)
      olpol = poles(1, 1:lastpol-2) + poles(2, 1:lastpol-2)*1i;
      olzer = poles(1, lastpol-1:end) + poles(2, lastpol-1:end)*1i;
    else
      olpol = poles(1, 1:lastpol) + poles(2, lastpol)*1i;
      olzer = poles(1, lastpol+1:end) + poles(2, lastpol+1)*1i;
    endif
  else
    poles(:,idx) = [];
    lastpol = length(olpol);
    if idx <= length(olpol)
      olpol = poles(1, 1:lastpol-1) + poles(2, 1:lastpol-1)*1i;
      olzer = poles(1, lastpol:end) + poles(2, lastpol)*1i;
    else
      olpol = poles(1, 1:lastpol) + poles(2, lastpol)*1i;
      olzer = poles(1, lastpol+1:end) + poles(2, lastpol+1)*1i;
    endif
  endif

  h3.sys = zpk (olzer, olpol', k);
  update_active_sys();
  h3.currentzpk = [];

  dynamics();
  refresh_main_plots();
endfunction

function visibleoff_controller(src, evt)
  set(3, 'Visible', 'off');
endfunction

## UI Elements

p = uipanel ("parent", fig3, "title", "Compensantor", "position", [.05 .8 .9 .18]);

## Editor List
h3.select_compensator = uicontrol ("parent", p,
                                "style", "popupmenu",
                                "units", "normalized",
                                "string", {"C", "F"},
                                "callback", @call_select,
                                "position", [0.05 0.3 .3 .4]);

h3.lbl_equal = uicontrol ("parent", p,
                                "style", "text",
                                "units", "normalized",
                                "string", " = ",
                                "horizontalalignment", "left", "position", [0.35 0.3 .3 .4]);

h3.lbl_num = uicontrol ("parent", fig3, "style", "text", "units", "normalized", "string", T(55:end-24), "horizontalalignment", "left", "verticalalignment", "middle", "position", [.62 .8 .3 .18]);

## Edit Box
h3.gain_box = uicontrol ("parent", fig3, "style", "edit", "units", "normalized", "string", "", "callback", @call_update_gain, "position", [.4 .86 .2 .05], 'backgroundcolor', 'white');

c3 = uicontextmenu (fig3);

h3.menu1 = uimenu ("parent", c3, 'label', "Add Pole/Zero ...");
h3.menu2 = uimenu ("parent", c3, 'label', "Delete Pole/Zero ...", 'callback', @(src, evt) delete_pz(src, evt));

h3.m1 = uimenu (h3.menu1, 'label', "'x' Real Pole", 'callback', @(src, evt) add_rpole(src, evt));
h3.m2 = uimenu (h3.menu1, 'label', "'xx' Complex Pole", 'callback', @(src, evt) add_cpole(src, evt));
h3.m3 = uimenu (h3.menu1, 'label', "'o' Real Zero", 'callback', @(src, evt) add_rzero(src, evt));
h3.m4 = uimenu (h3.menu1, 'label', "'oo' Complex Zero", 'callback', @(src, evt) add_czero(src, evt));
h3.m5 = uimenu (h3.menu1, 'label', "Integrator", 'callback', @(src, evt) add_integrator(src, evt));
h3.m6 = uimenu (h3.menu1, 'label', "Differentiator", 'callback', @(src, evt) add_differentiator(src, evt));
h3.m7 = uimenu (h3.menu1, 'label', "Lead", 'callback', @(src, evt) add_pending(src, evt));
h3.m8 = uimenu (h3.menu1, 'label', "Lag", 'callback', @(src, evt) add_pending(src, evt));
h3.m9 = uimenu (h3.menu1, 'label', "Notch", 'callback', @(src, evt) add_pending(src, evt));

set (fig3, "uicontextmenu", c3);

set(fig3, "color", get(0, "defaultuicontrolbackgroundcolor"))
set(fig3, 'Visible', 'off');
set(fig3, 'CloseRequestFcn', @visibleoff_controller);

guidata (fig3, h3);
dynamics();

