"""Convert DataFrame to HTML table."""
function df_to_html_table(df::DataFrame)
    # Convert column names to strings to ensure compatibility
    header = DOM.tr([DOM.th(string(col)) for col in names(df)])

    # Create rows
    rows = []
    for i in 1:nrow(df)
        # Round numeric values to 3 decimal places
        cells = []
        for col in names(df)
            val = df[i, col]
            cell_content = isa(val, Number) ? round(val, digits=3) : val
            push!(cells, DOM.td(cell_content))
        end
        push!(rows, DOM.tr(cells))
    end

    # Combine everything into a table
    return DOM.table(
        DOM.thead(header),
        DOM.tbody(rows),
        class="data-table"
    )
end