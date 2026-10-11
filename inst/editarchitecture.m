function editarchitecture()
  graphics_toolkit qt

  global fig4 h4 h1

  % Guarantee h4 exists as a valid structure BEFORE setting any fields
  if ~isstruct(h4)
    h4 = struct();
  endif

  % Ensure fig4 exists and set as current figure
  if isempty(fig4) || ~ishandle(fig4)
    fig4 = figure(4, "Name", "Edit Architecture", "NumberTitle", "off", "menubar", "none", "Visible", "off");
  endif

  set(0, 'currentfigure', fig4);
  clf(fig4);
  set(fig4, 'resize', 'off');

  % 1. Create Layout Axes First
  h4.ax7 = axes(); set(h4.ax7, "position", [0.25, 0.57, 0.72, 0.34]);
  h4.ax6 = axes(); set(h4.ax6, "position", [0.05, 0.10, 0.2, 0.1]);
  h4.ax5 = axes(); set(h4.ax5, "position", [0.05, 0.25, 0.2, 0.1]);
  h4.ax4 = axes(); set(h4.ax4, "position", [0.05, 0.40, 0.2, 0.1]);
  h4.ax3 = axes(); set(h4.ax3, "position", [0.05, 0.55, 0.2, 0.1]);
  h4.ax2 = axes(); set(h4.ax2, "position", [0.05, 0.70, 0.2, 0.1]);
  h4.ax1 = axes(); set(h4.ax1, "position", [0.05, 0.85, 0.2, 0.1]);

  % 2. Image Loading
  pkg_dir = fileparts(mfilename('fullpath'));
  img_dir = fullfile(pkg_dir, 'images');

  sisoconfig = cell(1, 6);
  for i = 1:6
    thumb_path = fullfile(img_dir, sprintf('SISOConfig%dThumb.png', i));
    if exist(thumb_path, 'file')
      sisoconfig{i} = im2double(imread(thumb_path));
    else
      sisoconfig{i} = zeros(100, 100, 3);
    endif
  endfor

  for i = 1:6
    config_path = fullfile(img_dir, sprintf('Config%d.png', i));
    field_name = sprintf('sisoCONFIG%d', i);
    if exist(config_path, 'file')
      h4.img.(field_name) = im2double(imread(config_path));
    else
      h4.img.(field_name) = zeros(300, 400, 3);
    endif
  endfor

  axes(h4.ax1); image(sisoconfig{1}); axis off; axis image;
  axes(h4.ax2); image(sisoconfig{2}); axis off; axis image;
  axes(h4.ax3); image(sisoconfig{3}); axis off; axis image;
  axes(h4.ax4); image(sisoconfig{4}); axis off; axis image;
  axes(h4.ax5); image(sisoconfig{5}); axis off; axis image;
  axes(h4.ax6); image(sisoconfig{6}); axis off; axis image;

  % 3. Create Block Table Panels & Edit Fields
  p4 = uipanel("Parent", fig4, "title", "Blocks", "position", [.25 .1 .75 .45]);
  gp2 = uibuttongroup("Parent", p4, "Position", [0 0.8 1 0.2]);

  uicontrol(gp2, "style", "text", "units", "normalized", "fontweight", "bold", "string", "Identifier", "horizontalalignment", "left", "position", [0 0 0.18 1]);
  uicontrol(gp2, "style", "text", "units", "normalized", "fontweight", "bold", "string", "Block Name", "horizontalalignment", "left", "position", [0.18 0 0.21 1]);
  uicontrol(gp2, "style", "text", "units", "normalized", "fontweight", "bold", "string", "Value", "horizontalalignment", "left", "position", [0.42 0 0.4 1]);

  gp3 = uibuttongroup("Parent", p4, "Position", [0 0 1 0.8]);

  h4.id_lbl = cell(7, 1);
  h4.id_edit = cell(7, 1);
  h4.val_edit = cell(7, 1);

  for r = 1:7
    yPos = 0.9 - (r - 1) * 0.15;
    h4.id_lbl{r} = uicontrol(gp3, "style", "text", "units", "normalized", "string", "", "horizontalalignment", "left", "position", [0.05 yPos 0.04 .1]);
    h4.id_edit{r} = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "", "horizontalalignment", "center", "position", [0.18 yPos 0.2 .1], 'backgroundcolor', 'white');
    h4.val_edit{r} = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "", "horizontalalignment", "center", "position", [0.42 yPos 0.5 .1], 'backgroundcolor', 'white');
  endfor

  % Action buttons
  h4.btn_ok = uicontrol("Parent", fig4, "style", "pushbutton", "units", "normalized", "string", "OK", "position", [0.66 0.01 0.1 0.06], 'callback', @call_ok);
  h4.btn_cancel = uicontrol("Parent", fig4, "style", "pushbutton", "units", "normalized", "string", "Cancel", "position", [0.78 0.01 0.1 0.06], 'callback', @call_cancell);
  h4.btn_help = uicontrol("Parent", fig4, "style", "pushbutton", "units", "normalized", "string", "Help", "position", [0.9 0.01 0.1 0.06], 'callback', @call_help);

  % 4. Instantiate Radio Buttons for Configuration Selection
  gp = uibuttongroup("Parent", fig4, "Position", [0 0 0.05 1]);

  h4.b6 = uicontrol(gp, "style", "radiobutton", "units", "normalized", "Position", [0.25 0.10 0.75 0.1], 'callback', @edit_architecture_cb);
  h4.b5 = uicontrol(gp, "style", "radiobutton", "units", "normalized", "Position", [0.25 0.25 0.75 0.1], 'callback', @edit_architecture_cb);
  h4.b4 = uicontrol(gp, "style", "radiobutton", "units", "normalized", "Position", [0.25 0.40 0.75 0.1], 'callback', @edit_architecture_cb);
  h4.b3 = uicontrol(gp, "style", "radiobutton", "units", "normalized", "Position", [0.25 0.55 0.75 0.1], 'callback', @edit_architecture_cb);
  h4.b2 = uicontrol(gp, "style", "radiobutton", "units", "normalized", "Position", [0.25 0.70 0.75 0.1], 'callback', @edit_architecture_cb);
  h4.b1 = uicontrol(gp, "style", "radiobutton", "units", "normalized", "Position", [0.25 0.85 0.75 0.1], 'callback', @edit_architecture_cb);

  set(fig4, "color", get(0, "defaultuicontrolbackgroundcolor"));
  set(fig4, 'CloseRequestFcn', @visibleoff_architecture);

  target_config = 1;
  if isfield(h1, 'architecture_idx') && ~isempty(h1.architecture_idx)
    target_config = h1.architecture_idx;
  endif

  set([h4.b1, h4.b2, h4.b3, h4.b4, h4.b5, h4.b6], 'value', 0);
  switch target_config
    case 1, set(h4.b1, 'value', 1);
    case 2, set(h4.b2, 'value', 1);
    case 3, set(h4.b3, 'value', 1);
    case 4, set(h4.b4, 'value', 1);
    case 5, set(h4.b5, 'value', 1);
    case 6, set(h4.b6, 'value', 1);
  endswitch

  h4.set_arch = target_config;
  update_architecture_view();
  set(fig4, 'Visible', 'on');
endfunction

% --- Dynamic View Updater ---
function update_architecture_view()
  global h4 h1

  if get(h4.b1, 'value'), cfg = 1;
  elseif get(h4.b2, 'value'), cfg = 2;
  elseif get(h4.b3, 'value'), cfg = 3;
  elseif get(h4.b4, 'value'), cfg = 4;
  elseif get(h4.b5, 'value'), cfg = 5;
  elseif get(h4.b6, 'value'), cfg = 6;
  else, cfg = 1;
  endif

  h4.set_arch = cfg;
  field_str = sprintf('sisoCONFIG%d', cfg);
  if isfield(h4.img, field_str)
    axes(h4.ax7); image(h4.img.(field_str)); axis off; axis normal;
  endif

  switch cfg
    case {1, 2, 3}
      ids = {'F', 'C', 'G', 'H'};
      vals = {get_sys_str(h1, 'F'), get_sys_str(h1, 'C'), get_sys_str(h1, 'G'), get_sys_str(h1, 'H')};
    case 4
      ids = {'C1', 'C2', 'G', 'H'};
      vals = {get_sys_str(h1, 'C1'), get_sys_str(h1, 'C2'), get_sys_str(h1, 'G'), get_sys_str(h1, 'H')};
    case 5
      ids = {'F', 'C', 'G1', 'G2', 'Gd'};
      vals = {get_sys_str(h1, 'F'), get_sys_str(h1, 'C'), get_sys_str(h1, 'G1'), get_sys_str(h1, 'G2'), get_sys_str(h1, 'Gd')};
    case 6
      ids = {'F', 'C1', 'C2', 'G1', 'G2', 'H1', 'H2'};
      vals = {get_sys_str(h1, 'F'), get_sys_str(h1, 'C1'), get_sys_str(h1, 'C2'), get_sys_str(h1, 'G1'), get_sys_str(h1, 'G2'), get_sys_str(h1, 'H1'), get_sys_str(h1, 'H2')};
  endswitch

  for r = 1:7
    if r <= length(ids)
      set(h4.id_lbl{r}, 'String', ids{r});
      set(h4.id_edit{r}, 'String', ids{r}, 'Enable', 'on');
      set(h4.val_edit{r}, 'String', vals{r}, 'Enable', 'on');
    else
      set(h4.id_lbl{r}, 'String', '');
      set(h4.id_edit{r}, 'String', '--', 'Enable', 'off');
      set(h4.val_edit{r}, 'String', '--', 'Enable', 'off');
    endif
  endfor
endfunction

function edit_architecture_cb(~, ~)
  update_architecture_view();
endfunction

% Helper to format models cleanly: shows plain constants for static gains and raw strings for plants/sensors
function s_str = get_sys_str(h1_struct, name)
  if any(strcmp(name, {'G', 'G1', 'G2', 'Gd', 'H1', 'H2'})) && isfield(h1_struct, [name '_str'])
    s_str = h1_struct.([name '_str']);
    return;
  endif

  if isfield(h1_struct, name)
    try
      sys = h1_struct.(name);
      [z, p, k] = zpkdata(sys, 'v');
      if isempty(z) && isempty(p)
        s_str = num2str(k);
      else
        [num, den] = tfdata(sys, 'v');

        % Clean up minor floating-point precision drift for near-integers
        num(abs(num - round(num)) < 1e-4) = round(num(abs(num - round(num)) < 1e-4));
        den(abs(den - round(den)) < 1e-4) = round(den(abs(den - round(den)) < 1e-4));

        s_str = sprintf('tf(%s, %s)', mat2str(num), mat2str(den));
      end
    catch
      s_str = '1';
    end_try_catch
  else
    s_str = '1';
  endif
endfunction

function call_ok(~, ~)
  global fig4 h4 h1 h3
  cfg = h4.set_arch;
  h1.architecture_idx = cfg;

  s = tf('s'); % Define s so transfer functions evaluate correctly

  % 1. Parse and update active workspace variables from table edit fields
  for r = 1:7
    id_str = get(h4.id_edit{r}, 'String');
    val_str = get(h4.val_edit{r}, 'String');
    if ~strcmp(id_str, '--') && ~isempty(id_str) && ~isempty(val_str)
      try
        parsed_sys = eval(val_str);
        h1.(id_str) = parsed_sys;
        % Save exact user string for plants/sensors so they retain their clean formatting
        if any(strcmp(id_str, {'G', 'G1', 'G2', 'Gd', 'H1', 'H2'}))
          h1.([id_str '_str']) = val_str;
        endif
      catch err
        errordlg(['Invalid syntax for block ', id_str, ': ', err.message], 'Syntax Error');
        return;
      end_try_catch
    endif
  endfor

  % 2. Synchronize main window plant input text box if G was changed
  if isfield(h1, 'enter_plant') && ishandle(h1.enter_plant) && isfield(h1, 'G_str')
    set(h1.enter_plant, 'String', h1.G_str);
  endif

  % 3. Synchronize Edit Controller active system (h3.sys) based on current selection
  if isfield(h3, 'select_compensator') && ishandle(h3.select_compensator)
    if get(h3.select_compensator, 'Value') == 2 && isfield(h1, 'F')
      h3.sys = h1.F;
    elseif isfield(h1, 'C')
      h3.sys = h1.C;
    endif
  elseif isfield(h1, 'C')
    h3.sys = h1.C;
  endif

  % 4. Safely close/delete Edit Architecture window
  if ishandle(fig4)
    delete(fig4);
    fig4 = [];
  endif

  % 5. Trigger full application refresh across main plots and controller panels using callback handle
  if isfield(h1, 'refresh_cb') && !isempty(h1.refresh_cb)
    feval(h1.refresh_cb);
  endif
endfunction

function visibleoff_architecture(~, ~)
  global fig4
  if ishandle(fig4)
    set(fig4, 'Visible', 'off');
  endif
endfunction

function call_cancell(~, ~)
  global fig4
  str1 = questdlg('Are you sure you want to leave this page without saving?');
  if strcmp(str1, "Yes") && ishandle(fig4)
    delete(fig4);
    fig4 = [];
  endif
endfunction

function call_help(~, ~)
  helpdlg('Access the following website for more information: https://eriveltongualter.github.io/GSoC2018/pages/documentation.html', 'Help');
endfunction
