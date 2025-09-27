#!/usr/bin/env python3
import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import uuid
import random
import csv
import math

# ---------- Helper functions ----------
def new_col_id():
    return str(uuid.uuid4())

def clamp(v, a, b):
    return max(a, min(b, v))

def format_decimals(dec):
    return f"0.{''.join(['0']*dec)}" if dec>0 else "0"

# ---------- Column model ----------
class Column:
    def __init__(self, name="col", col_id=None):
        self.id = col_id or new_col_id()
        self.name = name
        self.type = "Random"   # or "Fixed"
        self.min = 0.0
        self.max = 10.0
        self.fixed = 0.0
        self.decimals = 0
        self.linearity = {
            "enabled": False,
            "target_id": None,
            "weight": 0.0
        }

    def range_min(self):
        if self.type == "Random":
            return float(self.min)
        else:
            return float(self.fixed)

    def range_max(self):
        if self.type == "Random":
            return float(self.max)
        else:
            return float(self.fixed)

# ---------- Main App ----------
class SyntheticDataGUI(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Synthetic Data Generator")
        self.geometry("920x800")  # Increased height to accommodate preview table
        self.minsize(800, 600)

        self.columns = []  # list[Column]
        # start with 2 sample columns
        self.add_column("A")
        self.add_column("B")

        self._build_ui()

    # ---------- UI building ----------
    def _build_ui(self):
        # Create main paned window for resizable sections
        main_pane = ttk.PanedWindow(self, orient=tk.VERTICAL)
        main_pane.pack(fill=tk.BOTH, expand=True, padx=8, pady=6)

        # Top frame: controls and column definitions
        top_frame = ttk.Frame(main_pane)
        main_pane.add(top_frame, weight=1)

        # top frame: controls
        top = ttk.Frame(top_frame)
        top.pack(side="top", fill="x", padx=8, pady=6)

        add_btn = ttk.Button(top, text="Add column", command=self.ui_add_column)
        add_btn.pack(side="left", padx=(0,6))

        remove_btn = ttk.Button(top, text="Remove selected", command=self.ui_remove_selected)
        remove_btn.pack(side="left", padx=(0,6))

        ttk.Label(top, text="Rows to generate:").pack(side="left", padx=(12,4))
        self.rows_var = tk.IntVar(value=100)
        rows_spin = ttk.Spinbox(top, from_=1, to=1000000, textvariable=self.rows_var, width=8)
        rows_spin.pack(side="left", padx=(0,6))

        gen_btn = ttk.Button(top, text="Generate & Preview", command=self.generate_and_preview)
        gen_btn.pack(side="left", padx=(12,6))

        export_btn = ttk.Button(top, text="Export CSV", command=self.export_csv_dialog)
        export_btn.pack(side="left", padx=(0,6))

        ttk.Label(top, text="  ").pack(side="left", expand=True)  # spacer

        ttk.Label(top, text="Hint: Use Advanced→Linearity to link columns.").pack(side="right")

        # main area: scrollable frame with list of columns
        container = ttk.Frame(top_frame)
        container.pack(side="top", fill="both", expand=True, padx=8, pady=6)

        canvas = tk.Canvas(container)
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar = ttk.Scrollbar(container, orient="vertical", command=canvas.yview)
        scrollbar.pack(side="right", fill="y")
        canvas.configure(yscrollcommand=scrollbar.set)
        canvas.bind('<Configure>', lambda e: canvas.configure(scrollregion=canvas.bbox("all")))

        self.inner_frame = ttk.Frame(canvas)
        canvas.create_window((0,0), window=self.inner_frame, anchor='nw')

        # headers
        hdr = ttk.Frame(self.inner_frame)
        hdr.pack(fill="x", pady=(0,6))
        ttk.Label(hdr, text="Name", width=20).grid(row=0, column=0, sticky="w")
        ttk.Label(hdr, text="Type / Params", width=46).grid(row=0, column=1, sticky="w")
        ttk.Label(hdr, text="Rounding", width=10).grid(row=0, column=2)
        ttk.Label(hdr, text="Advanced", width=16).grid(row=0, column=3)

        # list area
        self.row_frames = {}
        self.selected_col_id = None

        self.refresh_column_list()

        # Bottom frame: Preview table
        bottom_frame = ttk.Frame(main_pane)
        main_pane.add(bottom_frame, weight=1)

        # Preview section
        preview_label = ttk.Label(bottom_frame, text="Preview (First 10 rows):", font=('Arial', 10, 'bold'))
        preview_label.pack(anchor='w', padx=8, pady=(8, 4))

        # Create frame for table and scrollbar
        table_container = ttk.Frame(bottom_frame)
        table_container.pack(fill='both', expand=True, padx=8, pady=(0, 8))

        # Create treeview for table display
        self.preview_tree = ttk.Treeview(table_container, show='headings', height=10)
        vsb = ttk.Scrollbar(table_container, orient="vertical", command=self.preview_tree.yview)
        hsb = ttk.Scrollbar(table_container, orient="horizontal", command=self.preview_tree.xview)
        self.preview_tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)

        # Pack the treeview and scrollbars
        self.preview_tree.grid(row=0, column=0, sticky='nsew')
        vsb.grid(row=0, column=1, sticky='ns')
        hsb.grid(row=1, column=0, sticky='ew')
        
        table_container.grid_rowconfigure(0, weight=1)
        table_container.grid_columnconfigure(0, weight=1)

        # Status label for preview
        self.preview_status = ttk.Label(bottom_frame, text="No data generated yet. Click 'Generate & Preview' to see sample data.")
        self.preview_status.pack(anchor='w', padx=8, pady=(0, 8))

    # ---------- Column management ----------
    def add_column(self, name="col"):
        c = Column(name=name)
        self.columns.append(c)
        return c

    def remove_column_by_id(self, cid):
        self.columns = [c for c in self.columns if c.id != cid]

    def find_column(self, cid):
        for c in self.columns:
            if c.id == cid:
                return c
        return None

    # ---------- UI callbacks ----------
    def ui_add_column(self):
        n = 1
        base = "col"
        existing = {c.name for c in self.columns}
        while f"{base}{n}" in existing:
            n += 1
        c = self.add_column(f"{base}{n}")
        self.refresh_column_list()
        # select new
        self.selected_col_id = c.id

    def ui_remove_selected(self):
        if not self.selected_col_id:
            messagebox.showinfo("Remove column", "Select a column row by clicking its name first.")
            return
        self.remove_column_by_id(self.selected_col_id)
        self.selected_col_id = None
        self.refresh_column_list()

    def refresh_column_list(self):
        # clear previous widgets
        for child in list(self.inner_frame.pack_slaves()):
            if child != self.inner_frame.pack_slaves()[0]:  # keep header (first)
                child.destroy()
        # rebuild header kept, but simpler: clear all except first header frame
        # find header by index 0 surface
        # better approach: destroy all after header index 0
        # rebuild rows
        for c in self.columns:
            self._create_column_row(c)

    def _create_column_row(self, col: Column):
        row = ttk.Frame(self.inner_frame, relief="ridge", padding=6)
        row.pack(fill="x", pady=4)

        # clicking name selects
        name_var = tk.StringVar(value=col.name)
        name_entry = ttk.Entry(row, textvariable=name_var, width=24)
        name_entry.grid(row=0, column=0, sticky="w")
        name_entry.bind("<FocusOut>", lambda e, cid=col.id, var=name_var: self._on_name_change(cid, var.get()))
        name_entry.bind("<Button-1>", lambda e, cid=col.id: self._on_row_select(cid))

        # Type + params frame
        params = ttk.Frame(row)
        params.grid(row=0, column=1, sticky="w", padx=(8,8))

        type_var = tk.StringVar(value=col.type)
        type_combo = ttk.Combobox(params, values=["Random", "Fixed"], width=8, state="readonly", textvariable=type_var)
        type_combo.grid(row=0, column=0, padx=(0,6))
        type_combo.bind("<<ComboboxSelected>>", lambda e, cid=col.id, var=type_var: self._on_type_change(cid, var.get()))
        # Random: min/max entries; Fixed: fixed
        min_var = tk.StringVar(value=str(col.min))
        max_var = tk.StringVar(value=str(col.max))
        fixed_var = tk.StringVar(value=str(col.fixed))

        min_entry = ttk.Entry(params, textvariable=min_var, width=10)
        min_entry.grid(row=0, column=1, padx=(0,4))
        ttk.Label(params, text="to").grid(row=0, column=2)
        max_entry = ttk.Entry(params, textvariable=max_var, width=10)
        max_entry.grid(row=0, column=3, padx=(4,8))

        fixed_entry = ttk.Entry(params, textvariable=fixed_var, width=12)
        # place fixed entry but hide or show based on type
        fixed_entry.grid(row=0, column=4, padx=(4,8))

        # rounding
        round_var = tk.IntVar(value=col.decimals)
        round_combo = ttk.Combobox(row, values=[0,1,2,3,4,5,6], width=4, state="readonly", textvariable=round_var)
        round_combo.grid(row=0, column=2)
        round_combo.bind("<<ComboboxSelected>>", lambda e, cid=col.id, var=round_var: self._on_round_change(cid, int(var.get())))

        # advanced button
        adv_btn = ttk.Button(row, text="Advanced ▾", width=12)
        adv_btn.grid(row=0, column=3, padx=(8,0))

        # advanced area (hidden by default)
        adv_frame = ttk.Frame(row)
        adv_frame.grid(row=1, column=0, columnspan=4, pady=(8,0), sticky="w")
        adv_frame.grid_remove()

        # contents of advanced: linearity
        lin_enabled_var = tk.BooleanVar(value=col.linearity["enabled"])
        lin_check = ttk.Checkbutton(adv_frame, text="Enable Linearity (follow another column)", variable=lin_enabled_var)
        lin_check.grid(row=0, column=0, sticky="w")
        # target selector and weight
        ttk.Label(adv_frame, text="Target:").grid(row=0, column=1, sticky="e", padx=(12,2))
        target_values = [ (c.name, c.id) for c in self.columns if c.id != col.id ]
        # if target list empty, provide placeholder
        if not target_values:
            target_combo = ttk.Combobox(adv_frame, values=["(no other columns)"], state="disabled", width=18)
        else:
            target_combo = ttk.Combobox(adv_frame, values=[tv[0] for tv in target_values], state="readonly", width=18)
            # set current if exists
            if col.linearity["target_id"]:
                found = next((i for i,tv in enumerate(target_values) if tv[1]==col.linearity["target_id"]), None)
                if found is not None:
                    target_combo.current(found)
        target_combo.grid(row=0, column=2, padx=(4,8))

        ttk.Label(adv_frame, text="Weight:").grid(row=0, column=3, padx=(8,2))
        weight_var = tk.DoubleVar(value=col.linearity["weight"])
        weight_spin = ttk.Spinbox(adv_frame, from_=0.0, to=1.0, increment=0.01, textvariable=weight_var, width=6)
        weight_spin.grid(row=0, column=4)
        weight_scale = ttk.Scale(adv_frame, from_=0.0, to=1.0, orient="horizontal", variable=weight_var, length=120)
        weight_scale.grid(row=0, column=5, padx=(8,0))

        # wire adv toggle button
        def toggle_adv():
            if adv_frame.winfo_ismapped():
                adv_frame.grid_remove()
                adv_btn.config(text="Advanced ▾")
            else:
                adv_frame.grid()
                adv_btn.config(text="Advanced ▴")
        adv_btn.config(command=toggle_adv)

        # update widgets visibility according to type
        def update_type_widgets():
            t = type_var.get()
            if t == "Random":
                min_entry.configure(state="normal")
                max_entry.configure(state="normal")
                fixed_entry.configure(state="disabled")
            else:
                min_entry.configure(state="disabled")
                max_entry.configure(state="disabled")
                fixed_entry.configure(state="normal")

        update_type_widgets()

        # bind entry updates
        def on_minmax_focus_out(e=None):
            try:
                col.min = float(min_var.get())
                col.max = float(max_var.get())
                if col.min > col.max:
                    col.min, col.max = col.max, col.min
                    min_var.set(str(col.min))
                    max_var.set(str(col.max))
            except Exception:
                pass

        def on_fixed_focus_out(e=None):
            try:
                col.fixed = float(fixed_var.get())
            except Exception:
                pass

        min_entry.bind("<FocusOut>", on_minmax_focus_out)
        max_entry.bind("<FocusOut>", on_minmax_focus_out)
        fixed_entry.bind("<FocusOut>", on_fixed_focus_out)

        # when combobox type changed
        def on_type_selected(e=None):
            col.type = type_var.get()
            update_type_widgets()

        type_combo.bind("<<ComboboxSelected>>", lambda e=None: on_type_selected())

        # name change handler
        # already bound above

        # rounding handler bound above

        # set initial values in widgets (in case)
        min_var.set(str(col.min))
        max_var.set(str(col.max))
        fixed_var.set(str(col.fixed))

        # clicking a row to 'select' it
        def on_click_row(event=None):
            self.selected_col_id = col.id
            # highlight selection visually
            for rf_cid, rf in self.row_frames.items():
                if rf_cid == col.id:
                    rf.config(style="Selected.TFrame")
                else:
                    rf.config(style="TFrame")

        row.bind("<Button-1>", lambda e: on_click_row())
        # also store refs for later updates
        self.row_frames[col.id] = row

        # store final update callbacks when user changes advanced widgets
        def apply_all_changes():
            col.name = name_var.get().strip() or col.name
            col.type = type_var.get()
            try:
                col.min = float(min_var.get())
            except Exception:
                pass
            try:
                col.max = float(max_var.get())
            except Exception:
                pass
            try:
                col.fixed = float(fixed_var.get())
            except Exception:
                pass
            col.decimals = int(round_var.get())
            col.linearity["enabled"] = bool(lin_enabled_var.get())
            col.linearity["weight"] = float(weight_var.get())
            # determine target id by name in current dropdown
            if isinstance(target_combo, ttk.Combobox) and target_combo['state'] != 'disabled':
                sel_name = target_combo.get()
                # find id by name
                for other in self.columns:
                    if other.id != col.id and other.name == sel_name:
                        col.linearity["target_id"] = other.id
                        break
                else:
                    # if no selection or not matched
                    col.linearity["target_id"] = None

        # call apply_all_changes when adv toggled or when leaving row
        for w in [name_entry, min_entry, max_entry, fixed_entry, round_combo, lin_check, weight_spin, target_combo]:
            w.bind("<FocusOut>", lambda e, f=apply_all_changes: f())

        # when columns list changes (someone added/renamed) we need to refresh target lists.
        # We'll rely on refresh_column_list to rebuild everything - keep simple.

    # ---------- simple callbacks to update model ----------
    def _on_name_change(self, cid, new_name):
        c = self.find_column(cid)
        if c:
            c.name = new_name.strip() or c.name
            # refresh to update target name lists
            self.refresh_column_list()

    def _on_type_change(self, cid, new_type):
        c = self.find_column(cid)
        if c:
            c.type = new_type
            self.refresh_column_list()

    def _on_round_change(self, cid, dec):
        c = self.find_column(cid)
        if c:
            c.decimals = dec

    def _on_row_select(self, cid):
        self.selected_col_id = cid
        # visual selection handled in row click

    # ---------- Generation logic ----------
    def generate_rows(self, nrows):
        # Validate and collect column metadata
        if not self.columns:
            raise RuntimeError("No columns defined")
        # ensure all names unique
        names = [c.name for c in self.columns]
        if len(set(names)) != len(names):
            # enforce uniqueness by appending small suffixes
            seen = {}
            for c in self.columns:
                if c.name in seen:
                    seen[c.name] += 1
                    c.name = f"{c.name}_{seen[c.name]}"
                else:
                    seen[c.name] = 1

        # Produce base values
        base_values = { c.id: [] for c in self.columns }
        for c in self.columns:
            for _ in range(nrows):
                if c.type == "Random":
                    a = float(c.min)
                    b = float(c.max)
                    if a == b:
                        val = a
                    else:
                        val = random.random() * (b - a) + a
                else:
                    val = float(c.fixed)
                base_values[c.id].append(val)

        # Now apply linearity adjustments
        final_values = { c.id: [v for v in base_values[c.id]] for c in self.columns }

        # We'll process adjustments in simple pass: for each column with linearity enabled,
        # map target base value to source's min/max and mix with weight.
        for c in self.columns:
            lin = c.linearity
            if lin["enabled"] and lin["target_id"]:
                target = self.find_column(lin["target_id"])
                if not target:
                    continue
                w = clamp(float(lin["weight"]), 0.0, 1.0)
                smin = c.range_min()
                smax = c.range_max()
                tmin = target.range_min()
                tmax = target.range_max()
                # precompute denominators
                t_range = tmax - tmin
                s_range = smax - smin
                for i in range(nrows):
                    base_val = base_values[c.id][i]
                    tval = base_values[target.id][i]
                    # map tval into source's range:
                    if t_range == 0:
                        # target constant: use its value, scaled by midpoint mapping to source range
                        mapped = smin + (s_range * 0.5) if s_range != 0 else smin
                    else:
                        frac = (tval - tmin) / t_range
                        mapped = smin + frac * s_range
                    new_val = (1.0 - w) * base_val + w * mapped
                    final_values[c.id][i] = new_val

        # apply rounding according to decimals
        rows = []
        for i in range(nrows):
            row = {}
            for c in self.columns:
                dec = int(c.decimals)
                val = final_values[c.id][i]
                # apply rounding
                if dec == 0:
                    val = int(round(val))
                else:
                    val = round(val, dec)
                row[c.name] = val
            rows.append(row)
        return rows

    def generate_and_preview(self):
        n_preview = 10
        nrows = self.rows_var.get()
        
        if nrows < n_preview:
            n_preview = nrows
            
        try:
            data = self.generate_rows(n_preview)
            self.update_preview_table(data)
            self.preview_status.config(text=f"Preview showing first {n_preview} rows. Total rows to generate: {nrows}")
        except Exception as e:
            messagebox.showerror("Error generating", str(e))
            self.preview_status.config(text="Error generating preview data")

    def update_preview_table(self, data):
        """Update the preview table with generated data"""
        # Clear existing data
        for item in self.preview_tree.get_children():
            self.preview_tree.delete(item)
            
        # Clear existing columns
        for col in self.preview_tree["columns"]:
            self.preview_tree.heading(col, text="")
            self.preview_tree.column(col, width=0)
        
        # Set up new columns
        if not self.columns:
            return
            
        columns = [c.name for c in self.columns]
        self.preview_tree["columns"] = columns
        
        # Configure column headers
        for col_name in columns:
            self.preview_tree.heading(col_name, text=col_name)
            self.preview_tree.column(col_name, width=100, minwidth=80, anchor='center')
        
        # Add data rows
        for i, row in enumerate(data):
            values = [row[col_name] for col_name in columns]
            self.preview_tree.insert("", "end", values=values, tags=('evenrow' if i % 2 == 0 else 'oddrow',))
        
        # Configure row colors for better readability
        self.preview_tree.tag_configure('evenrow', background='#f0f0f0')
        self.preview_tree.tag_configure('oddrow', background='white')

    # ---------- Export ----------
    def export_csv_dialog(self):
        nrows = self.rows_var.get()
        if nrows <= 0:
            messagebox.showinfo("Rows required", "Please specify a number of rows > 0.")
            return
        fname = filedialog.asksaveasfilename(title="Save CSV", defaultextension=".csv",
                                            filetypes=[("CSV files","*.csv"),("All files","*.*")])
        if not fname:
            return
        try:
            data = self.generate_rows(nrows)
            with open(fname, "w", newline="", encoding="utf-8") as f:
                writer = csv.DictWriter(f, fieldnames=[c.name for c in self.columns])
                writer.writeheader()
                for row in data:
                    writer.writerow(row)
            messagebox.showinfo("Exported", f"Wrote {nrows} rows to:\n{fname}")
        except Exception as e:
            messagebox.showerror("Error", str(e))


# ---------- Run the app ----------
if __name__ == "__main__":
    app = SyntheticDataGUI()
    app.mainloop()
