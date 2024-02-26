load("render.star", "render")

def main(config):
    return render.Root(
        child = render.Text(config.get("text") or "text")
    )